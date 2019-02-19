package MooX::PluginKit::ConsumerRole;

our $VERSION = '0.05';

=head1 NAME

MooX::PluginKit::ConsumerRole - Common functionality for PluginKit consumers.

=head2 DESCRIPTION

This role alters C<BUILDARGS> to replace the C<plugins> argument with the
L</plugin_factory> argument.

Using this role by itself isn't all that useful.  Instead head on over to
L<MooX::PluginKit::Consumer>.

=cut

use MooX::PluginKit::Core;
use MooX::PluginKit::Factory;
use Types::Standard -types;

use Moo::Role;
use strictures 2;
use namespace::clean;

around BUILDARGS => sub{
    my $orig = shift;
    my $class = shift;
    my $args = $class->$orig( @_ );

    my $factory = MooX::PluginKit::Factory->new(
        plugins   => delete( $args->{plugins} ) || [],
        namespace => get_consumer_namespace( $class ),
    );

    $args->{plugin_factory} = $factory;

    return $args;
};

=head1 ARGUMENTS

=head2 plugin_factory

The L<MooX::PluginKit::Factory> used to apply plugins to a class.
There shouldn't be a reason to set this argument directly.  Instead
you'll want to set the C<plugins> argument which gets pseudo-coerced
into this argument.

=cut

has plugin_factory => (
    is  => 'ro',
    isa => InstanceOf[ 'MooX::PluginKit::Factory' ],
);

sub class_new_with_plugins {
    my $self = shift;
    my $class = shift;

    return $self->plugin_factory->class_new( $class, @_ );
}

1;
__END__

=head1 AUTHORS AND LICENSE

See L<MooX::PluginKit/AUTHOR> and L<MooX::PluginKit/LICENSE>.

