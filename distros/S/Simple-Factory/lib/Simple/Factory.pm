package Simple::Factory;
{
    $Simple::Factory::VERSION = '0.09';
}
use strict;
use warnings;

#ABSTRACT: simple factory

use feature 'switch';
use Carp qw(carp croak confess);
use Module::Runtime qw(use_module);
use Try::Tiny;
use Scalar::Util qw(blessed);

use Moo;
use MooX::HandlesVia;
use MooX::Types::MooseLike::Base qw(HasMethods HashRef Any Bool CodeRef);
use namespace::autoclean;

has build_class => (
    is       => 'ro',
    required => 1,
    coerce   => sub {
        my ($class) = @_;
        use_module($class);
    }
);

has build_conf => (
    is          => 'ro',
    isa         => HashRef [Any],
    required    => 1,
    handles_via => 'Hash',
    handles     => {
        has_build_conf_for  => 'exists',
        get_build_conf_for  => 'get',
        get_supported_keys  => 'keys',
        _add_build_conf_for => 'set',
    }
);

has fallback     => ( is => 'ro', predicate => 1 );
has build_method => ( is => 'ro', default   => sub { "new" } );
has autoderef    => ( is => 'ro', isa       => Bool, default => sub { 1 } );
has silence      => ( is => 'ro', isa       => Bool, default => sub { 0 } );
has cache =>
  ( is => 'ro', isa => HasMethods [qw(get set remove)], predicate => 1 );

has inline => ( is => 'ro', isa => Bool, default => sub { 0 } );
has eager  => ( is => 'ro', isa => Bool, default => sub { 0 } );
has on_error => (
    is      => 'ro',
    isa     => CodeRef,
    default => sub { "croak" },
    coerce  => sub {
        my ($on_error) = @_;

        return $on_error if ref($on_error) eq 'CODE';

        given ($on_error) {
            when ("croak") {
                return sub {
                    my $key = $_[0]->{key};
                    croak "cant resolve instance for key '$key': "
                      . $_[0]->{exception};
                  }
            }
            when ("confess") {
                return sub {
                    my $key = $_[0]->{key};
                    confess "cant resolve instance for key '$key': "
                      . $_[0]->{exception};
                  }
            }
            when ("carp") {
                return sub {
                    my $key = $_[0]->{key};
                    carp "cant resolve instance for key '$key': "
                      . $_[0]->{exception};
                    return;
                  }
            }
            when ("fallback") {
                return sub {
                    return $_[0]->{factory}
                      ->get_fallback_for_key( $_[0]->{key} );
                  }
            }
            when ("undef") {
                return sub { undef }
            }
            default {
                croak
"can't coerce on_error '$on_error', please use: carp, confess, croak, fallback or undef";
            }
        }
    }
);

sub BUILDARGS {
    my ( $self, @args ) = @_;

    if ( scalar(@args) == 1 ) {
        unshift @args, "build_class";
    }
    my (%hash_args) = @args;

    if (   scalar(@args) >= 2
        && !exists $hash_args{build_class}
        && !exists $hash_args{build_conf} )
    {
        my $build_class = $args[0];
        my $build_conf  = $args[1];

        $hash_args{build_class} = $build_class;
        $hash_args{build_conf}  = $build_conf;

        if ( $hash_args{inline} ) {
            $hash_args{build_conf} =
              { map { $_ => { $_ => $build_conf->{$_} } } keys %{$build_conf},
              };
        }
    }

    return \%hash_args;
}

sub BUILD {
    my ($self) = @_;

    $self->_coerce_build_method;

    if ( $self->eager ) {
        $self->resolve($_) for $self->get_supported_keys;
    }

    return;
}

sub _coerce_build_method {
    my ($self) = @_;

    my $class        = $self->build_class;
    my $build_method = $self->build_method;

    my $method = $class->can( $self->build_method )
      or croak
      "Error: class '$class' does not support build method: $build_method";

    return $method;
}

sub _build_object_from_args {
    my ( $self, $args, $key ) = @_;

    my $class  = $self->build_class;
    my $method = $self->_coerce_build_method;

    if ( $self->autoderef && ref($args) ) {
        given ( ref($args) ) {
            when ('ARRAY')  { return $class->$method( @{$args} ); }
            when ('HASH')   { return $class->$method( %{$args} ); }
            when ('SCALAR') { return $class->$method( ${$args} ); }
            when ('REF')    { return $class->$method( ${$args} ); }
            when ('GLOB')   { return $class->$method( *{$args} ); }
            when ('CODE')   { return $class->$method( $args->($key) ); }
            default {
                carp(   "cant autoderef argument ref('"
                      . ref($args)
                      . "') for class '$class'" )
                  if !$self->silence;
            }
        }
    }

    return $class->$method($args);
}

sub get_fallback_for_key {
    my ( $self, $key ) = @_;

    return $self->_build_object_from_args( $self->fallback, $key );
}

sub resolve {
    my ( $self, $key ) = @_;

    my $class = $self->build_class;
    if ( $self->has_build_conf_for($key) ) {
        return try {
            $self->_build_object_from_args( $self->get_build_conf_for($key),
                $key );
        }
        catch {
            $self->on_error->(
                { exception => $_, factory => $self, key => $key } );
        };
    }
    elsif ( $self->has_fallback ) {
        return $self->get_fallback_for_key($key);
    }

    confess("instance of '$class' named '$key' not found");
}

sub add_build_conf_for {
    my ( $self, $key, $conf, %conf ) = @_;

    if ( $self->has_build_conf_for($key) && $conf{not_override} ) {
        croak("cannot override exiting configuration for key '$key'");
    }
    elsif ( $self->has_build_conf_for($key) ) {

        # if we are using cache
        # and we substitute the configuration for some reason
        # we should first remove the cache for this particular key
        $self->_cache_remove($key);
    }

    return $self->_add_build_conf_for( $key => $conf );
}

sub _get_urn_for_cache {
    my ( $self, $key ) = @_;

    join q<:>, $self->build_class, $key;
}

sub _cache_remove {
    my ( $self, $key ) = @_;

    return if !$self->has_cache;

    $self->cache->remove( $self->_get_urn_for_cache($key) );
}

sub _cache_set {
    my ( $self, $key, $value ) = @_;

    return if !$self->has_cache;

    my $urn = $self->_get_urn_for_cache($key);

    $self->cache->set( $urn => $value );
}

sub _cache_get {
    my ( $self, $key ) = @_;

    return if !$self->has_cache;

    my $urn = $self->_get_urn_for_cache($key);

    my $cached = $self->cache->get($urn);

    return $cached if $cached;
}

around [qw(resolve get_fallback_for_key)] => sub {
    my $orig = shift;
    my ( $self, $key, @keys ) = @_;

    my $cached_value = $self->_cache_get($key);

    return $cached_value->[0] if $cached_value;

    my $instance = $self->$orig($key);

    $self->_cache_set( $key => [$instance] );

    if ( scalar(@keys) && $instance->can('resolve') ) {
        return $instance->$orig(@keys);
    }

    return $instance;
};

1;

__END__ 

=head1 NAME

Simple::Factory - a simple factory to create objects easily, with cache, autoderef and fallback supports

=head1 SYNOPSYS

    use Simple::Factory;

    my $factory = Simple::Factory->new(
        'My::Class' => {
            first  => { value => 1 },
            second => [ value => 2 ],
        },
        fallback => { value => undef }, # optional. in absent, will die if find no key
    );

    my $first  = $factory->resolve('first');  # will build a My::Class instance with arguments 'value => 1'
    my $second = $factory->resolve('second'); # will build a My::Class instance with arguments 'value => 2'
    my $last   = $factory->resolve('last');   # will build a My::Class instance with fallback arguments

=head1 DESCRIPTION

This is one way to implement the L<Factory Pattern|http://www.oodesign.com/factory-pattern.html>. The main objective is substitute one hashref of objects ( or coderefs who can build/return objects ) by something more intelligent, who can support caching and fallbacks. If the creation rules are simple we can use C<Simple::Factory> to help us to build instances.

We create instances with C<resolve> method. It is lazy. If you need build all instances (to store in the cache) consider try to resolve them first.

If you need something more complex, consider some framework of Inversion of Control (IoC).

For example, we can create a simple factory to create DateTime objects, using CHI as cache:

   my $factory = Simple::Factory->new(
        build_class  => 'DateTime',
        build_method => 'from_epoch',
        build_conf   => {
            one      => { epoch => 1 },
            two      => { epoch => 2 },
            thousand => { epoch => 1000 }
        },
        fallback => sub { epoch => $_[0] }, # fallback can receive the key
        cache    => CHI->new( driver => 'Memory', global => 1),
    );

  $factory->resolve( 1024 )->epoch # returns 1024

IMPORTANT: if the creation fails ( like some excetion from the constructor ), we will B<not> call the C<fallback>. 
Check L</on_error> attribute to change the default behavior.

=head1 ATTRIBUTES

=head2 build_class

Specify the perl package ( class ) used to create instances. Using C<Method::Runtime>, will die if can't load the package.

This argument is required. You can omit by using the C<build_class> as a first argument of the constructor.

=head2 build_args

Specify the mapping of key => arguments, storing in a hashref.

This argument is required. You can omit by using the C<build_class> and C<build_args> as a first pair of arguments.

Important: if C<autoderef> is true, we will try to deref the value before use to create an instance. 

=head2 fallback

The default behavior is die if we try to resolve an instance using one non-existing key.

But if fallback is present, we will use this on the constructor.

If C<autoderef> is true and fallback is a code reference, we will call the code and pass the key as an argument.

=head2 build_method

By default the C<Simple::Factory> calls the method C<new> but you can override and specify your own build method.

Will croak if the C<build_class> does not support the method on C<resolve>.

=head2 autoderef

If true ( default ), we will try to deref the argument present in the C<build_conf> only if it follow this rules:

=over 4

=item * 

will deref only references

=item * 

if the reference is an array, we will call the C<build_method> with C<@$array>.  

=item * 

if the reference is a hash, we will call the C<build_method> with C<%$hash>.

=item * 

if the reference is a scalar or other ref, we will call the C<build_method> with C<$$ref>.

=item * 

if the reference is a glob, we will call the C<build_method> with C<*$glob>.

=item * 

if the reference is a code, we will call the C<build_method> with $code->( $key ) ( same thinf for the fallback )

=item * 

other cases (like Regexes) we will carp if it is not in C<silence> mode. 

=back

=head2 silence

If true ( default is false ), we will omit the carp message if we can't C<autoderef>.

=head2 cache

If present, we will cache the result of the method C<resolve>. The cache should responds to C<get>, C<set> and C<remove> like L<CHI|CHI>.

We will also cache fallback cases. The key used on the cache is C<build_class>:C<key>, to be possible share the same cache with many factories.

If we need add a new build_conf via C<add_build_conf_for>, and override one existing configuration, we will remove it from the cache if possible.

default: not present

=head2 inline 

B<Experimental> feature. useful to create multiple inline definitions. See L</resolve> method.

This feature can change in the future.

=head2 eager

If true, will force C<resolve> all configure keys when build the object. Useful to force caching all of them.

default: false.

=head2 on_error

Change the default behavior of what happens if build one instance throws on error.

Accepts a coderef. You can also use three initial shortcuts ( will be coerce to coderef ): C<croak>, C<carp>, C<confess>, C<fallback> and C<undef>.

=over 4

=item *

C<croak> will croak the exception + extra message about the key ( B<default> ).

=item * 

C<confess> will confess, instead croak the exception.

=item *

C<carp> will just carp instead croak and return undef.

=item * 

C<fallback> will resolve the fallback ( but in case of exception will die - to avoid one potential deadlock ).

=item *

C<undef> will return an undefined value.

=back

Example:

    my $factory = Simple::Factory->new(
        Foo => { ... },
        fallback => -1,
        on_error => "fallback" # in case of some exception, call the fallback
    );

If one coderef was used, it will be called with one hashref as argument with three fields:

=over 4

=item * 

C<key> with the value of the key 

=item * 

C<factory> one reference for the factory itself

=item *

C<exception> with the error message

=back

Example:

    my $factory =  Simple::Factory->new(
        Foo => { a => 1 },
        on_error => sub { $logger->warn("error while resolve key '$_[0]->{key}' : '$_[0]->{exception}'; undef },
    );

    $factory->resolve("b"); # will call 'on_error', log the exception and return undef

=head1 METHODS

=head2 add_build_conf_for

usage: add_build_conf_for( key => configuration [, options ])

Can add a new build configuration for one specific key. It is possible add new or just override.

You can change the behavior using an hash of options. 

Options: you can avoid override one existing configuration with C<not_override> and a true value.

Will remove C<cache> if possible.

Example:

    $factory->add_build_conf_for( last => { foo => 1, bar => 2 }); # can override
    $factory->add_build_conf_for( last => { ... }, not_override => 1); # will croak instead override

=head2 resolve

usage: resolve( key [, keys ] )

The main method. Will build one instance of C<build_class> using the C<build_conf> and C<build_method>. 

Should receive a key and if does not exist a C<build_conf> will try use the fallback if specified, or will die ( confess ).

If the C<cache> attribute is present, will try to return first one object from the cache using the C<key>, or will resolve and
store in the cache for the next call.

You can pass multiple keys. If the instance responds to C<resolve> method, we will call with the rest of the keys. It is useful
for inline many factories.

Example:

    my $factory = Simple::Factory->new(
        'Simple::Factory' => {
            Foo => {
                build_class => 'Foo',
                build_conf => {
                    one => 1,
                    two => 2,
                }
            },
            Bar => {
                Bar => {
                    first => { ... },
                    last => { ... },
                }
            }
        }
    );

    my $object = $factory->resolve('Foo', 'one'); # shortcut to ->resolve('Foo')->resolve('one');

Or, using C<inline> experimental option.

    my $factory = Simple::Factory->new(
        'Simple::Factory'=> {
            Foo => { one => 1, two => 2 },
            Bar => { first => 0, last => -1},
        },
        inline => 1,
    );

If we have some exception when we try to create an instance for one particular key, we will not call the C<fallback>. 
We use C<fallback> when we can't find the C<build_conf> based on the key. 

To change the behavior check the attr C<on_error>.

=head2 get_fallback_for_key 

this method will try to resolve the fallback. can be useful on C<on_error> coderefs. accept the same argument as C<resolve>.

=head1 SEE ALSO

=over 4

=item L<Bread::Board|Bread::Board>

A solderless way to wire up your application components.

=item L<IOC|IOC>

A lightweight IOC (Inversion of Control) framework

=back

=head1 LICENSE

The MIT License
 
 Permission is hereby granted, free of charge, to any person
 obtaining a copy of this software and associated
 documentation files (the "Software"), to deal in the Software
 without restriction, including without limitation the rights to
 use, copy, modify, merge, publish, distribute, sublicense,
 and/or sell copies of the Software, and to permit persons to
 whom the Software is furnished to do so, subject to the
 following conditions:
  
  The above copyright notice and this permission notice shall
  be included in all copies or substantial portions of the
  Software.
   
   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT
   WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
   INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
   MERCHANTABILITY, FITNESS FOR A PARTICULAR
   PURPOSE AND NONINFRINGEMENT. IN NO EVENT
   SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
   LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
   LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
   TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
   CONNECTION WITH THE SOFTWARE OR THE USE OR
   OTHER DEALINGS IN THE SOFTWARE.

=head1 AUTHOR

Tiago Peczenyj <tiago (dot) peczenyj (at) gmail (dot) com>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/peczenyj/simple-factory-p5/issues>
