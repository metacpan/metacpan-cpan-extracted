package Starch::Store::Catalyst::Plugin::Session;

$Starch::Store::Catalyst::Plugin::Session::VERSION = '0.04';

=head1 NAME

Starch::Store::Catalyst::Plugin::Session - Starch storage backend using
Catalyst::Plugin::Session stores.

=head1 SYNOPSIS

    my $starch = Starch->new(
        store => {
            class => '::Catalyst::Plugin::Session',
            store_class => '::File',
            session_config => {
                storage => '/tmp/session',
            },
        },
    );

=head1 DESCRIPTION

This L<Starch> store uses L<Catalyst::Plugin::Session> stores
to set and get state data.

The reason this module exists is to make the migration from
the Catalyst session plugin to Starch as painless as possible.

=cut

use Catalyst::Plugin::Session::Store;
use Moose::Meta::Class qw();
use Types::Standard -types;
use Types::Common::String -types;
use Starch::Util qw( load_prefixed_module );

use Moo;
use strictures 2;
use namespace::clean;

with qw(
    Starch::Store
);

after BUILD => sub{
    my ($self) = @_;

    # Get this loaded as early as possible.
    $self->store();

    return;
};

{
    package # NO CPAN INDEX
        Starch::FakeCatalystContext;

    use Moose;
    extends 'Catalyst::Component';
    use Class::C3::Adopt::NEXT;
    use Log::Any qw($log);

    has config => ( is=>'ro' );

    sub _session_plugin_config {
        return $_[0]->config->{session};
    }

    sub setup_session {
        $_[0]->maybe::next::method();
    }

    sub debug { 0 }

    sub log { $log }
}

=head1 REQUIRED ARGUMENTS

=head2 store_class

The full class name for the L<Catalyst::Plugin::Session::Store> you
wish to use.

If the store class starts with C<::> then it will be considered
relative to C<Catalyst::Plugin::Session::Store>.  For example, if
you set this to C<::File> then it will be internally translated to
C<Catalyst::Plugin::Session::Store::File>.

=cut

has store_class => (
    is       => 'ro',
    isa      => NonEmptySimpleStr,
    required => 1,
);

=head1 OPTIONAL ARGUMENTS

=head2 session_config

The configuration of the session plugin.

=cut

has session_config => (
    is      => 'ro',
    isa     => HashRef,
    default => sub{ {} },
);

=head1 ATTRIBUTES

=head2 store

This is the L<Catalyst::Plugin::Session::Store> object built from the
L</store_class> and with a fake Catalyst superclass to make everything
work.

=cut

has store => (
    is       => 'lazy',
    init_arg => undef,
);
sub _build_store {
    my ($self) = @_;

    my $store_class = load_prefixed_module(
        'Catalyst::Plugin::Session::Store',
        $self->store_class(),
    );

    my $class = Moose::Meta::Class->create_anon_class(
        superclasses => [
            'Starch::FakeCatalystContext',
            $store_class,
        ],
    );

    my $store = $class->new_object(
        config => {
            session => $self->session_config(),
            'Plugin::Session' => $self->session_config(),
        },
    );

    $store->setup_session();

    return $store;
}

=head1 METHODS

=head2 set

See L<Starch::Store/set>.  Calls C<store_session_data> on L</store>.

=head2 get

See L<Starch::Store/get>.  Calls C<get_session_data> on L</store>.

=head2 remove

See L<Starch::Store/remove>.  Calls C<delete_session_data> on L</store>.

=cut

sub set {
    my ($self, $id, $namespace, $data, $expires) = @_;

    local $Carp::Internal{ (__PACKAGE__) } = 1;

    $self->store->store_session_data( "session:$id", $data );

    return;
}

sub get {
    my ($self, $id, $namespace) = @_;

    local $Carp::Internal{ (__PACKAGE__) } = 1;

    return $self->store->get_session_data( "session:$id" );
}

sub remove {
    my ($self, $id, $namespace) = @_;

    local $Carp::Internal{ (__PACKAGE__) } = 1;

    $self->store->delete_session_data( "session:$id" );

    return;
}

1;
__END__

=head1 SUPPORT

Please submit bugs and feature requests to the
Starch-Store-Catalyst-Plugin-Session GitHub issue tracker:

L<https://github.com/bluefeet/Starch-Store-Calatlyst-Plugin-Session/issues>

=head1 AUTHOR

Aran Clary Deltac <bluefeetE<64>gmail.com>

=head1 ACKNOWLEDGEMENTS

Thanks to L<ZipRecruiter|https://www.ziprecruiter.com/>
for encouraging their employees to contribute back to the open
source ecosystem.  Without their dedication to quality software
development this distribution would not exist.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

