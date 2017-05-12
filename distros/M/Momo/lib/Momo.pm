package Momo;

# ABSTRACT: a simple oop module inspired from Mojo::Base and Moo
use utf8;
use strict;
use warnings;
use Carp;
use Role::Tiny ();
use Scalar::Util qw(set_prototype);
use Class::Method::Modifiers;

our $VERSION = 1.2;

sub import {
    my $class = shift;

    {
        no strict 'refs';
        no warnings 'redefine';

        my $package = caller;
        push @{ $package . '::ISA' }, 'Momo';
        # install methodes into package,make the package get magic feature
        # install class method modifiers
        if( not defined &{ $package."::has" } ){
            *{ $package . '::has' } = sub { attr( $package, @_ ) };
        }
        if( not defined &{ $package."::extends" } ) {
            *{ $package . '::extends' } = sub {
            for (@_) {
                ( my $file = $_ ) =~ s!::|'!/!g;
                eval { require "$file.pm" };
                push @{ $package . '::ISA' }, $_;
            }
            };
        }
        if( not defined &{ $package."::with" } ){
        *{ $package . '::with' } = sub {
            Role::Tiny->apply_roles_to_package( $package, @_ );
        };
        }
        for my $method (qw(before after around)) {
            *{ $package . '::' . $method } = sub {
                Class::Method::Modifiers::install_modifier( $package, $method,
                    @_ );
            };
        }
        set_prototype \&{ $package . '::extends' }, '@';
        set_prototype \&{ $package . '::with' },    '@';
    }
    strict->import;
    warnings->import;
    utf8->import;
    Carp->import;
    if ( $] >= 5.010 ) {
        require 'feature.pm';
        feature->import( ':' . substr("$^V",1,4) );
    }

}

sub new {
    my $class = shift;
    bless @_ ? @_ > 1 ? {@_} : { %{ $_[0] } } : {}, ref $class || $class;
}

sub attr {
    my ( $class, $attrs, $default ) = @_;
    return unless ( $class = ref $class || $class ) && $attrs;

    Carp::croak 'Default has to be a code reference or constant value'
      if ref $default && ref $default ne 'CODE';

    # Compile attributes
    for my $attr ( @{ ref $attrs eq 'ARRAY' ? $attrs : [$attrs] } ) {
        Carp::croak qq{Attribute "$attr" invalid}
          unless $attr =~ /^[a-zA-Z_]\w*$/;

        my $code = "package $class;\nsub $attr {\n  if (\@_ == 1) {\n";
        unless ( defined $default ) { $code .= "    return \$_[0]{'$attr'};" }
        else {
            $code .= "    return \$_[0]{'$attr'} if exists \$_[0]{'$attr'};\n";
            $code .= "    return \$_[0]{'$attr'} = ";
            $code .=
              ref $default eq 'CODE' ? '$default->($_[0]);' : '$default;';
        }

        $code .= "\n  }\n  \$_[0]{'$attr'} = \$_[1];\n";
        $code .= "  \$_[0];\n}";

        no strict 'refs';
        warn "-- Attribute $attr in $class\n$code\n\n" if $ENV{MOMO_DEBUG};
        Carp::croak "Momo error: $@" unless eval "$code;1";
    }
}

sub tap {
    my ( $self, $cb ) = @_;
    $_->$cb for $self;
    return $self;
}

1;

=encoding utf8

=head1 NAME

Momo,a simple oop module inspired from Mojo::Base and Moo.

=head1 SYNOPSIS

    
    package Person;

    use Momo;
    
    has name => 'james'; # if not set,default set james
    has [qw(age sex)];

    sub new{
        say "I'm a Person";
    }

    1;

=head1 DESCRIPTION

Why I want to write this module? If you heard about Moose or Moo,you know they 
are pretty module for perl object-oriented program.
Compare with old style of perl5 object-oriented program:

    
    package Foo;

    BEGIN{
        push @ISA,"Some::SuperClass";
    } # or 
    use base 'Some::SuperClass';

    sub new{
        my $self = bless {} shift;
        $self->{name} = shift;
        $self->{age} = shift;
        return $self;
    }

    sub some_method{
        say "I'm some method";
    }

    1;

    # invoke method as oop style
    my $obj = Foo->new;
    $obj->some_method;

In moose or moo,write like this:

    package Foo;

    use Moose; # or use Moo
    
    extends 'SomeBaseClass' with 'role1','role2';

    has x => ( is => 'rw',default => sub { {} },lazy => 1);
    has y => ( is => 'ro',default => ref {} );
    has z => ( is => 'rw',default => sub { { xx => 'yy'} },required => 1);

    before method1 => sub {
        .....
    };

    after method1 => sub {
    };

    around method1 => sub {
    };

    1;

It looks so amazing,everything works fine,L<Moose> can give you vast powerful feature
of perl Object-Oriented,the syntax sugars like 'extends','has','with'...etc are magic.
On the other hand,you can override the attribute with C<has +x>,and also,with the role
make it more inconceivable.

But,I still find some problem:

=over 4

=item the cumbersome syntax in C<has> defined
  
Every time when I type the C<has> blabla,does this below is really I want?

    has ua=> ( is => 'rw',isa => 'LWP::UserAgent',
        default => sub { LWP::UserAgent->new },lazy => 1);
    # is => 'rw', over and over,lazy => 1, over and over,default,over and
    # over....
    # It makes me creazy!

You know perl is a dynamically typed language,not like java ,c++,I think I don't need 
the feature,even I almost do not used this feature,I also write ruby and python,but I 
never see this.

=item inherit some class of non Moose modules

In L<Moose> or L<Moo>,if you want to inherit a calss of non Moose style,all I know is 
to use L<MooseX::NonMoose>;

      package Term::VT102::NBased;
      use Moose;
      use MooseX::NonMoose;
      extends 'Term::VT102';

      has [qw/x_base y_base/] => (
          is      => 'ro',
          isa     => 'Int',
          default => 1,
      );

      around x => sub {
          my $orig = shift;
          my $self = shift;
          $self->$orig(@_) + $self->x_base - 1;
      };

      # ... (wrap other methods)

      no Moose;
      # no need to fiddle with inline_constructor here
      __PACKAGE__->meta->make_immutable;

      my $vt = Term::VT102::NBased->new(x_base => 0, y_base => 0);

or:

    package Crawler::Event;

    use Moo;

    extends 'Object::Event','Moo::Object';

    # explicit constructor
    sub new {
        my $class = shift;

        # call Mojo::UserAgent's constructor
        my $obj = $class->SUPER::new(@_);
        return $class->meta->new_object(
            # pass in the constructed object
            # using the special key __INSTANCE__
            __INSTANCE__ => $obj,
            @_,    # pass in the normal args
        );
    }

    1;

It looks so weird,this is just a simple object inherit,why I need to type so many
code and install a Moosex module.
Also,there is another way to fix this,use C<deligation> 

    package Website;

    use Moose;

    has 'uri' => (
      is      => 'ro',
      isa     => 'URI',
      handles => {
          hostname => 'host',
          path     => 'path',
      },
    );

But I think this is more complex,if you lost some method of handles,when you run
your code which just need to inherit LWP,then throw a error like:

    Can't find this method

Oh my god,why I must do this?

=item speed of runtime slowly

Although,Moo have make moose looks tidy and simple,at runtime,it still cost more 
time than old style of perl Object-Oriented program.

Here is the benchmark of Momo,Moose,Moo,hashref,bless hashref,each test create a 
object and access the attr,set the attr:

    Benchmark: timing 1000000 iterations of blessed_hashref, hashref, momo, moo, moose...
    blessed_hashref: 1.60316 wallclock secs ( 1.60 usr +  0.00 sys =  1.60 CPU) @ 625000.00/s (n=1000000)
       hashref: 1.34393 wallclock secs ( 1.35 usr +  0.00 sys =  1.35 CPU) @ 740740.74/s (n=1000000)
          momo: 3.97532 wallclock secs ( 3.97 usr +  0.00 sys =  3.97 CPU) @ 251889.17/s (n=1000000)
           moo: 5.36459 wallclock secs ( 5.37 usr +  0.00 sys =  5.37 CPU) @ 186219.74/s (n=1000000)
         moose: 7.81556 wallclock secs ( 7.81 usr +  0.00 sys =  7.81 CPU) @ 128040.97/s (n=1000000)
                        Rate     moose       moo      momo blessed_hashref   hashref
    moose           128041/s        --      -31%      -49%            -80%      -83%
    moo             186220/s       45%        --      -26%            -70%      -75%
    momo            251889/s       97%       35%        --            -60%      -66%
    blessed_hashref 625000/s      388%      236%      148%              --      -16%
    hashref         740741/s      479%      298%      194%             19%        --

The result shows that Momo is faster than Moo,Moose.

=back

When I develop mojo app,I found C<Mojo::Base> is so simple and light,fast speed,
and I add some features like : role,method modifiers,everything works fine for me.

Anyway,if you hate all of these,try L<Momo>,or you can keep working on  L<Moose> or L<Moo>.

It's so simple:

    package MomoStyle;

    use Momo;
    extends 'LWP::UserAgent'; #inherit LWP::UserAgent so easy
    with 'Logger'; # does a logging role,same as moose's role

    has name => 'momo';
    has city => 'beijing';
    has check => sub {
        my $self = shift;
        if( $name eq 'momo' ){
            # do some stuff here
        }
    };
    # if you need do some other thing,you can override new 
    sub new{
        my $self = shift->SUPER::new(@_);
        $self->agent("momo");
        $self;
    }

    1;


=head1 FUNCTIONS

L<Momo> exports the following functions 

=head2 has

  has 'name';
  has [qw(name1 name2 name3)];
  has name => 'foo';
  has name => sub {...};
  has [qw(name1 name2 name3)] => 'foo';
  has [qw(name1 name2 name3)] => sub {...};

Create attributes for hash-based objects, just like the L<Moose> has or L<Moo>,
but ignore the option of C<is>,C<isa>...

=head1 METHODS

L<Momo> implements the following methods.

=head2 new

  my $object = BaseSubClass->new;
  my $object = BaseSubClass->new(name => 'value');
  my $object = BaseSubClass->new({name => 'value'});

This base class provides a basic constructor for hash-based objects. You can
pass it either a hash or a hash reference with attribute values.

=head2 attr

  $object->attr('name');
  BaseSubClass->attr('name');
  BaseSubClass->attr([qw(name1 name2 name3)]);
  BaseSubClass->attr(name => 'foo');
  BaseSubClass->attr(name => sub {...});
  BaseSubClass->attr([qw(name1 name2 name3)] => 'foo');
  BaseSubClass->attr([qw(name1 name2 name3)] => sub {...});

Create attribute accessor for hash-based objects, an array reference can be
used to create more than one at a time. Pass an optional second argument to
set a default value, it should be a constant or a callback. The callback will
be executed at accessor read time if there's no set value. Accessors can be
chained, that means they return their invocant when they are called with an
argument.

=head2 extends

use this to inherit a class,different with Moose's extends,you can extends any
other module,what if they are blessed style module,

    extends 'LWP::UserAgent';
    extends 'BaseClass1','BaseClass2';

=head2 with 

use this to does a role,about role you can check L<Moose::Role>

    extends 'Mojo::Lite';
    with 'Some::Role';

    1;

=head2 method_modifiers

Same as Moo and Moose,Momo support method modifiers in Class or Role:
    
    package Role1;

    use Momo::Role;

    before some_method => sub { print "i'm before method" };
    after some_method => sub { print "i'm after method" };
    around some_method => sub { $_[1]->$_[0](@_) };

in class package:

    package Cat;

    use Momo;

    before feed => sub { print "I want to eat some water" };
    after feed => sub { print "after feed,I'm full" };
    around feed => sub { print "I should eat what" };
    sub feed { print "I want to feed ..." };

=head2 tap

  $object = $object->tap(sub {...});

K combinator, tap into a method chain to perform operations on an object
within the chain. The object will be the first argument passed to the callback
and is also available as C<$_>.


=head1 DEBUGGING

You can set the C<MOMO_DEBUG> environment variable to get some advanced
diagnostics information printed to C<STDERR>.

  MOMO_DEBUG=1

=head1 SEE ALSO

L<Mojo::Base>,L<Moo>,L<Moose>,L<Role::Tiny>

=head1 TODO

=over 4

=item support MOP

=item write C<attr> with XS

=back

=head1 BUGS

Any bugs just email C<yiming.jin@live.com>,or commit a issue on github:
L<https://github.com/niumang/momo/issues>

=head1 AUTHOR

舌尖上的牛氓 C<yiming.jin@live.com>  

QQ: 492003149

QQ-Group: 211685345

Site: L<http://perl-china.com>

=head1 Copyright

Copyright (C) <2013>, <舌尖上的牛氓>.

This module is free software; you
can redistribute it and/or modify it under the same terms
as Perl 5.10.0. For more details, see the full text of the
licenses in the directory LICENSES.

This program is distributed in the hope that it will be
useful, but without any warranty; without even the implied
warranty of merchantability or fitness for a particular purpose.

=cut

# niumang // vim: ts=4 sw=4 expandtab
# TODO - Edit.

