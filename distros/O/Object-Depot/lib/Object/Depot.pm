package Object::Depot;
our $VERSION = '0.01';
use strictures 2;

=encoding utf8

=head1 NAME

Object::Depot - Decouple object instantiation from usage.

=head1 SYNOPSIS

    use Object::Depot;
    
    my $depot = Object::Depot->new(
        class => 'CHI',
        # CHI->new returns a CHI::Driver object.
        type => InstanceOf[ 'CHI::Driver' ],
    );
    
    $depot->add_key(
        sessions => {
            driver => 'Memory',
            global => 1,
        },
    );
    
    $depot->store( ip2geo => CHI->new(...) );
    
    my $sessions = $depot->fetch('sessions');
    my $ip2geo = $depot->fetch('ip2geo');

=head1 DESCRIPTION

Object depots encapsulate object construction so that users of objects
do not need to know how to create the objects in order to use them.

The primary use case for this library is for storing the connection
logic to external services and making these connections globally
available to all application logic.  See L<Object::Depot::Singleton>
for turning your depot object into a global singleton.

=cut

use Guard qw( guard );
use Object::Depot::Singleton qw();
use Carp qw();
use Role::Tiny qw();
use Scalar::Util qw( blessed );
use Sub::Name qw( subname );
use Types::Common::String qw( NonEmptySimpleStr );
use Types::Standard qw( Bool CodeRef HashRef Object InstanceOf );

sub croak {
    local $Carp::Internal{'Object::Depot'} = 1;
    goto &Carp::croak;
}

sub croakf {
    my $msg = shift;
    $msg = sprintf( $msg, @_ );
    @_ = ( $msg );
    goto &croak;
}

use Moo;
use namespace::clean;

sub _normalize_args {
    my ($self, $args) = @_;

    return {} if !@$args;
    return $args->[0] if @$args==1 and ref($args->[0]) eq 'HASH';
    return { @$args } unless @$args % 2;

    croakf(
        'Odd number of arguments passed to %s()',
        scalar( caller ),
    );
}

sub _process_key_arg {
    my ($self, $args) = @_;

    my $caller_sub_name = (caller 1)[3];
    $caller_sub_name = '__ANON__' if !defined $caller_sub_name;
    $caller_sub_name =~ s{^.*::}{};

    my $key;

    $key = shift @$args
        if @$args and !blessed $args->[0];

    if ($self->_has_default_key() and !defined $key) {
        $key = $self->default_key();
    }
    else {
        croak "No key was passed to $caller_sub_name()"
            if !defined $key;

        if (!NonEmptySimpleStr->check( $key )) {
            $key = defined($key) ? ["$key"] : 'UNDEF';
            croak "Invalid key, $key, passed to $caller_sub_name(): " .
                  NonEmptySimpleStr->message( $key );
        }
    }

    $key = $self->_aliases->{$key} if exists $self->_aliases->{$key};

    if ($self->strict_keys() and !exists $self->_key_args->{$key}) {
        $key = defined($key) ? qq["$key"] : 'UNDEF';
        croak "Undeclared key, $key, passed to $caller_sub_name()"
    }

    return $key;
}

sub _export {
    my $self = shift;
    my $package = shift;

    return if !$self->_has_export_name();

    my $name = $self->export_name();
    my $do_it = $self->always_export();

    foreach my $arg (@_) {
        if (defined($arg) and $arg eq $name) {
            $do_it = 1;
            next;
        }

        croakf(
            'Unknown export, %s, passed to %s',
            defined($arg) ? qq["$arg"] : 'undef',
            $package,
        );
    }

    return if !$do_it;

    my $sub = subname $name => sub{ $self->fetch(@_) };
    { no strict 'refs'; *{"$package\::$name"} = $sub };

    return;
}

has _all_objects => (
    is      => 'ro',
    default => sub{ {} },
);

sub _objects {
    my ($self) = @_;

    return $self->_all_objects() if !$self->per_process();

    my $key = $$;
    $key .= '-' . threads->tid() if $INC{'threads.pm'};

    return $self->_all_objects->{$key} ||= {};
}

has _key_args => (
    is      => 'ro',
    default => sub{ {} },
);

has _aliases => (
    is      => 'ro',
    default => sub{ {} },
);

has _injections => (
    is      => 'ro',
    default => sub{ {} },
);

=head1 ARGUMENTS

=head2 class

    class => 'CHI',

The class which objects in this depot are expected to be.  This
argument defaults the L</constructor> and L</type> arguments.

Does not have a default.

Leaving this argument unset causes L</fetch> to fail on keys that were
not first populated with L</store> as the L</constructor> subroutine
will just return C<undef>.

=cut

has class => (
    is        => 'ro',
    isa       => NonEmptySimpleStr,
    predicate => '_has_class',
);

=head2 constructor

    constuctor => sub{
        my ($depot, $args) = @_;
        return $depot->class->new( $args );
    },

Set this to a code ref to control how objects get constructed.

When declaring a custom constructor be careful not to create memory
leaks via circular references.

L</create> validates the objects produced by this constructor and will
throw an exception if they do not match L</type>.

The default code ref is similar to the above example if L</class> is
set.  If it is not set then the default code ref will return C<undef>.

=cut

has constructor => (
    is  => 'lazy',
    isa => CodeRef,
);

my $class_constructor = sub{
    my $depot = shift;
    return $depot->class->new( @_ );
};

my $undef_constructor = sub{ undef };

sub _build_constructor {
    my ($self) = @_;
    return $class_constructor if $self->_has_class();
    return $undef_constructor;
}

=head2 type

    type => InstanceOf[ 'CHI::Driver' ],

Set this to a L<Type::Tiny> type to control how objects in the depot
are validated when they are stored.

Defaults to C<InstanceOf> L</class>, if set.  If the class is not set
then this defaults to C<Object> (both are from L<Types::Standard>).

=cut

has type => (
    is  => 'lazy',
    isa => InstanceOf[ 'Type::Tiny' ],
);

sub _build_type {
    my ($self) = @_;
    return InstanceOf[ $self->class() ] if $self->_has_class();
    return Object;
}

=head2 per_process

    per_process => 1,

Turn this on to store objects per-process; meaning, if the TID (thread
ID) or PID (process ID) change then this depot will act as if no
objects have been stored.  Generally you will not want to turn this
on.  On occasion, though, some objects are not thread or forking safe
and it is necessary.

Defaults off.

=cut

has per_process => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

=head2 disable_store

    disable_store => 1,

When on this causes L</store> to silently not store, causing all
L</fetch> calls for non-injected keys to return a new object.

Defaults off.

=cut

has disable_store => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

=head2 strict_keys

    strict_keys => 1,

Turn this on to require that all keys used must first be declared
via L</add_key> before they can be stored in the depot.

Defaults to off, meaning keys may be used without having to
pre-declare them.

=cut

has strict_keys => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

=head2 default_key

    default_key => 'generic',

If no key is passed to key-accepting methods like L</fetch> then they
will use this default key if available.

Defaults to no default key.

=cut

has default_key => (
    is        => 'ro',
    isa       => NonEmptySimpleStr,
    predicate => '_has_default_key',
);

=head2 key_argument

    key_argument => 'connection_key',

When set, this causes L</arguments> to include an extra argument to be
passed to the class during object construction.  The argument's key
will be whatever you set this to and the value will be the key used to
fetch the object.

You will still need to write the code in your class to capture the
argument, such as:

    has connection_key => ( is=>'ro' );

Defaults to no key argument.

=cut

has key_argument => (
    is        => 'ro',
    isa       => NonEmptySimpleStr,
    predicate => '_has_key_argument',
);

=head2 default_arguments

    default_arguments => {
        arg => 'value',
        ...
    },

When set, these arguments will be included in calls to L</arguments>.

Defaults to an empty hash ref.

=cut

has default_arguments => (
    is      => 'lazy',
    isa     => HashRef,
    default => sub{ {} },
);

=head2 export_name

    export_name => 'myapp_cache',

Set the name of a function that L<Object::Depot::Singleton> will
export to importers of your depot package.

Has no default.  If this is not set, then nothing will be exported.

=cut

has export_name => (
    is        => 'ro',
    isa       => NonEmptySimpleStr,
    predicate => '_has_export_name',
);

=head2 always_export

    always_export => 1,

Turning this on causes L<Object::Depot::Singleton> to always export
the L</export_name>, rather than only when listed in the import
arguments. This is synonymous with the difference between
L<Exporter>'s C<@EXPORT_OK> and C<@EXPORT>.

=cut

has always_export => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

=head1 METHODS

=head2 fetch

    my $object = $depot->fetch( $key );

=cut

sub fetch {
    my $self = shift;

    my $key = $self->_process_key_arg( \@_ );
    croak 'Too many arguments passed to fetch()' if @_;

    return $self->_fetch( $key );
}

sub _fetch {
    my ($self, $key) = @_;

    my $object = $self->_objects->{$key};
    return $object if $object;

    return undef if !$self->_has_class();

    $object = $self->_create( $key, {} );

    $self->_store( $key, $object );

    return $object;
}

=head2 store

    $depot->store( $key => $object );

=cut

sub store {
    my $self = shift;

    my $key = $self->_process_key_arg( \@_ );
    croak 'Too many arguments passed to store()' if @_>1;
    croak 'Not enough arguments passed to store()' if @_<1;

    my $object = shift;
    croakf(
        'Invalid object passed to store(): %s',
        $self->type->get_message( $object ),
    ) if !$self->type->check( $object );

    croak qq[Already stored key, "$key", passed to store()]
        if exists $self->_objects->{$key};

    return $self->_store( $key, $object );
}

sub _store {
    my ($self, $key, $object) = @_;

    return if $self->disable_store();

    $self->_objects->{$key} = $object;

    return;
}

=head2 remove

    $depot->remove( $key );

=cut

sub remove {
    my $self = shift;

    my $key = $self->_process_key_arg( \@_ );
    croak 'Too many arguments passed to remove()' if @_;

    return $self->_remove( $key );
}

sub _remove {
    my ($self, $key) = @_;

    return delete $self->_objects->{$key};
}

=head2 create

    my $object = $depot->create( $key, %extra_args );

Gathers arguments from L</arguments> and then calls L</constructor>
on them, returning a new object.  Extra arguments may be passed and
they will take precedence.

=cut

sub create {
    my $self = shift;

    my $key = $self->_process_key_arg( \@_ );

    my $extra_args = $self->_normalize_args( \@_ );

    return $self->_create( $key, $extra_args );
}

sub _create {
    my ($self, $key, $extra_args) = @_;

    my $args = $self->_arguments( $key, $extra_args );

    my $object = $self->constructor->( $self, $args );

    croakf(
        'Constructor returned an invalid value, %s, for key %s: %s',
        defined($object) ? (ref($object) || qq["$object"]) : 'UNDEF',
        qq["$key"],
        $self->type->get_message( $object ),
    ) if !$self->type->check( $object );

    return $object;
}

=head2 arguments

    my $args = $depot->arguments( $key, %extra_args );

This method returns an arguments hash ref that would be used to
instantiate a new L</class> object. You could, for example, use this
to produce a base-line set of arguments, then sprinkle in some more,
and make yourself a special mock object to be injected.

=cut

sub arguments {
    my $self = shift;

    my $key = $self->_process_key_arg( \@_ );

    my $extra_args = $self->_normalize_args( \@_ );

    return $self->_arguments( $key, $extra_args );
}

sub _arguments {
    my ($self, $key, $extra_args) = @_;

    my $args = {
        %{ $self->default_arguments() },
        %{ $self->_key_args->{$key} || {} },
        %$extra_args,
    };

    $args->{ $self->key_argument() } = $key
        if $self->_has_key_argument();

    return $args;
}

=head2 declared_keys

    my $keys = $depot->declared_keys();
    foreach my $key (@$keys) { ... }

Returns an array ref containing all the keys declared with
L</add_key>.

=cut

sub declared_keys {
    my $self = shift;
    return [ keys %{ $self->_key_args() } ];
}

=head2 inject

    $depot->inject( $key, $object );

Takes an object of your making and forces L</fetch> to return the
injected object.  This is useful for injecting mock objects in tests.

The injected object must validate against L</type>.

=cut

sub inject {
    my $self = shift;

    my $key = $self->_process_key_arg( \@_ );
    croak 'Too many arguments passed to inject()' if @_>1;
    croak 'Not enough arguments passed to inject()' if @_<1;

    my $object = shift;
    croakf(
        'Invalid object passed to inject(): %s',
        $self->type->get_message( $object ),
    ) if !$self->type->check( $object );

    croak qq[Already injected key, "$key", passed to inject()]
        if exists $self->_injections->{$key};

    $self->_injections->{$key} = $object;

    return;
}

=head2 inject_with_guard

    my $guard = $depot->inject_with_guard( $key => $object );

This is just like L</inject> except it returns a L<Guard> object
which, when it leaves scope and is destroyed, will automatically
call L</clear_injection>.

=cut

sub inject_with_guard {
    my $self = shift;

    my $key = $self->_process_key_arg( \@_ );

    $self->inject( $key, @_ );

    return guard {
        return $self->clear_injection( $key );
    };
}

=head2 clear_injection

    my $object = $depot->clear_injection( $key );

Removes and returns the injected object, restoring the original
behavior of L</fetch>.

=cut

sub clear_injection {
    my $self = shift;

    my $key = $self->_process_key_arg( \@_ );
    croak 'Too many arguments passed to clear_injection()' if @_;

    return delete $self->_injections->{$key};
}

=head2 injection

    my $object = $depot->injection( $key );

Returns the injected object, or C<undef> if none has been injected.

=cut

sub injection {
    my $self = shift;

    my $key = $self->_process_key_arg( \@_ );
    croak 'Too many arguments passed to injection()' if @_;

    return $self->_injections->{ $key };
}

=head2 has_injection

    if ($depot->has_injection( $key )) { ... }

Returns true if an injection is in place for the specified key.

=cut

sub has_injection {
    my $self = shift;

    my $key = $self->_process_key_arg( \@_ );
    croak 'Too many arguments passed to has_injection()' if @_;

    return exists($self->_injections->{$key}) ? 1 : 0;
}

=head2 add_key

    $depot->add_key( $key, %arguments );

Declares a new key and, optionally, the arguments used to construct
the L</class> object.

Arguments are optional, but if present they will be saved and used
by L</fetch> when calling C<new()> (via L</arguments>) on L</class>.

=cut

sub add_key {
    my ($self, $key, @args) = @_;

    croakf(
        'Invalid key, %s, passed to add_key(): %s',
        defined($key) ? qq["$key"] : 'UNDEF',
        NonEmptySimpleStr->get_message( $key ),
    ) if !NonEmptySimpleStr->check( $key );

    croak "Already declared key, \"$key\", passed to add_key()"
        if exists $self->_key_args->{$key};

    $self->_key_args->{$key} = $self->_normalize_args( \@args );

    return;
}

=head2 alias_key

    $depot->alias_key( $alias_key => $real_key );

Adds a key that is an alias to another key.

=cut

sub alias_key {
    my ($self, $alias, $key) = @_;

    croakf(
        'Invalid alias, %s, passed to alias_key(): %s',
        defined($alias) ? qq["$alias"] : 'UNDEF',
        NonEmptySimpleStr->get_message( $alias ),
    ) if !NonEmptySimpleStr->check( $alias );

    croakf(
        'Invalid key, %s, passed to alias_key(): %s',
        defined($key) ? qq["$key"] : 'UNDEF',
        NonEmptySimpleStr->get_message( $key ),
    ) if !NonEmptySimpleStr->check( $key );

    croak "Already declared alias, \"$alias\", passed to alias_key()"
        if exists $self->_aliases->{$alias};

    croak "Undeclared key, \"$key\", passed to alias_key()"
        if $self->strict_keys() and !exists $self->_key_args->{$key};

    $self->_aliases->{$alias} = $key;

    return;
}

1;
__END__

=head1 SUPPORT

Please submit bugs and feature requests to the
Object-Depot GitHub issue tracker:

L<https://github.com/bluefeet/Object-Depot/issues>

=head1 ACKNOWLEDGEMENTS

Thanks to L<ZipRecruiter|https://www.ziprecruiter.com/> for
encouraging their employees to contribute back to the open source
ecosystem. Without their dedication to quality software development
this distribution would not exist.

=head1 AUTHOR

    Aran Clary Deltac <bluefeet@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2020 Aran Clary Deltac

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see L<http://www.gnu.org/licenses/>.

=cut

