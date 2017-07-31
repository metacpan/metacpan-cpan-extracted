package MooseX::DIC::Container::DefaultImpl;

use MooseX::DIC::Types;
use List::Util 'reduce';
use Module::Load 'load';
use aliased 'MooseX::DIC::PackageIsNotServiceException';
use aliased 'MooseX::DIC::FunctionalityNotImplementedException';
use aliased 'MooseX::DIC::ContainerConfigurationException';
use aliased 'MooseX::DIC::UnregisteredServiceException';
use MooseX::DIC::ServiceFactoryFactory 'build_factory';

use Moose;
with 'MooseX::DIC::Container';

has environment => ( is => 'ro', isa => 'Str', default => 'default' );
has singletons => (
    is      => 'ro', isa         => 'HashRef[HashRef[Injectable]]',
    default => sub   { { default => {} } }
);
has services => (
    is  => 'ro',
    isa => 'HashRef[HashRef[MooseX::DIC::Container::ServiceMetaInformation]]',
    default => sub { { default => {} } }
);
has service_factories =>
    ( is => 'ro', isa => 'HashRef[ServiceFactory]', default => sub { {} } );

sub get_service {
    my ( $self, $package_name ) = @_;

    # Check it is a registered service
    my $meta = $self->get_service_meta($package_name);

    my $service;

    # If it is a singleton, there's a chance it has already been built
    if ( $meta->scope eq 'singleton' ) {

        # First retrieve it from the environment, then from default environment
        $service = $self->singletons->{ $meta->environment }->{$package_name};
        $service = $self->singletons->{'default'}->{$package_name}
            unless $service;
    }
    return $service if $service;

    # If the service hasn't been built yet, use the builder class to do it
    my $service_factory = $self->get_service_factory( $meta->builder );
    $service = $service_factory->build_service($meta);

    # Cache the service if it's a singleton
    if ( $meta->scope eq 'singleton' ) {
        $self->singletons->{ $meta->environment }->{$package_name} = $service;
    }

    return $service;
}

sub get_service_meta {
    my ( $self, $package_name ) = @_;

    my $meta = $self->services->{ $self->environment }->{$package_name};
    $meta = $self->services->{'default'}->{$package_name} unless $meta;
    UnregisteredServiceException->throw( service => $package_name )
        unless $meta;

    return $meta;
}

sub get_service_factory {
    my ( $self, $factory_type ) = @_;

    my $service_factory = $self->service_factories->{$factory_type};
    unless ($service_factory) {
        $service_factory = build_factory( $factory_type, $self );
        $self->service_factories->{$factory_type} = $service_factory;
    }

    return $service_factory;
}

sub register_service {
    my ( $self, $package_name ) = @_;

    # Make sure the the package is loaded
    load $package_name;

    # Check the package is an Injectable class
    my $injectable_role = reduce {$a}
    grep { $_->{package} eq 'MooseX::DIC::Injectable' }
        $package_name->meta->calculate_all_roles_with_inheritance;
    PackageIsNotServiceException->throw( package => $package_name )
        unless defined $injectable_role;

    # Get the meta information from the injectable role
    my $meta = $package_name->get_service_metadata;
    ContainerConfigurationException->throw( message =>
            "The package $package_name is not propertly configured for injection"
    ) unless $meta;

    # Build the implements info if it doesn't exist
    unless ( $meta->has_implements ) {
        FunctionalityNotImplementedException->throw( message =>
                'Injectable services must declare what interface they implement'
        );
    }

    # Until qualifiers are implemented, check the service has not already been
    # registered for the implemented interface for the given environment.
    if (
        exists $self->services->{ $meta->environment }->{ $meta->implements }
        ) {
        ContainerConfigurationException->throw( message =>
                'A service has already been declared for the Interface '
                . $meta->implements );
    }

    # Associate the service meta information to the interface this service implements
    $self->services->{ $meta->environment }->{ $meta->implements } = $meta;

}

1;
