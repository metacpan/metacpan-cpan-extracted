package MooX::PluginKit::Factory;

our $VERSION = '0.05';

=head1 NAME

MooX::PluginKit::Factory - Dynamically apply plugins to classes at runtime.

=head1 SYNOPSIS

    use MooX::PluginKit::Factory;
    
    my $kit = MooX::PluginKit::Factory->new(
        plugins => [...],
        namespace => ...,
    );
    
    my $object = $kit->class_new('Some::Class', %args);

=head1 DESCRIPTION

A PluginKit factory takes a list of plugins and then provides methods
for applying those plugins to classes and building objects from those classes.

Unless you are a power user you are better off using
L<MooX::PluginKit::Consumer>.

=cut

use MooX::PluginKit::Core;
use Types::Standard -types;
use Types::Common::String -types;
use Module::Runtime qw( require_module );

use Moo;
use strictures 2;
use namespace::clean;

=head1 ARGUMENTS

=head2 plugins

An array ref of plugin names (relative or absolute).

=cut

has plugins => (
    is      => 'ro',
    isa     => ArrayRef[ NonEmptySimpleStr ],
    default => sub{ [] },
);

=head2 namespace

The namespace to resolve relative plugin names to.

=cut

has namespace => (
    is  => 'ro',
    isa => NonEmptySimpleStr,
);

=head1 ATTRIBUTES

=head2 resolved_plugins

L</plugins> with all relative plugin names resolved.

=cut

has resolved_plugins => (
    is       => 'lazy',
    init_arg => undef,
);
sub _build_resolved_plugins {
    my ($self) = @_;

    return [
        map { resolve_plugin( $_, $self->namespace() ) }
        @{ $self->plugins() }
    ];
}

=head1 METHODS

=head2 build_class

    my $new_class = $kit->build_class( $class );

Creates a new class with all applicable L</plugins> applied to it
and returns the new class name.

=cut

sub build_class {
    my ($self, $base_class) = @_;

    return build_class_with_plugins(
        $base_class,
        @{ $self->resolved_plugins() },
    );
}

=head2 class_new

    my $object = $kit->class_new( $class, %args );

Calls L</build_class> and then creates an object of that class.
If the class to be built is a plugin consumer then
L<MooX::PluginKit::ConsumerRole/plugin_factory> will be defaulted
to this factory.

=cut

sub class_new {
    my $self = shift;
    my $base_class = shift;

    my $class = $self->build_class( $base_class );
    require_module $class if !$class->can('new');
    my $args = $class->BUILDARGS( @_ );

    if (is_consumer $class) {
        $args->{plugin_factory} ||= $self;
    }

    return $class->new( $args );
}

1;
__END__

=head1 AUTHORS AND LICENSE

See L<MooX::PluginKit/AUTHOR> and L<MooX::PluginKit/LICENSE>.

