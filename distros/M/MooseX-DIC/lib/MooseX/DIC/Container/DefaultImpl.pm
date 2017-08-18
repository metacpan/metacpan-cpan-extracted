package MooseX::DIC::Container::DefaultImpl;

use MooseX::DIC::Types;
use aliased 'MooseX::DIC::UnregisteredServiceException';
use aliased 'MooseX::DIC::ServiceRegistry';
use MooseX::DIC::ServiceFactoryFactory 'build_factory';

use Moose;
with 'MooseX::DIC::Container';

has environment => ( is => 'ro', isa => 'Str', default => 'default' );
has registry => (is => 'ro', isa => 'MooseX::DIC::ServiceRegistry', required => 1);
has singletons => (is => 'ro', isa => 'HashRef[HashRef[Any]]', default => sub { { default => {} } });
has service_factories => ( is => 'ro', isa => 'HashRef[ServiceFactory]', default => sub { {} } );

sub has_service {
  my ( $self, $interface_name ) = @_;

  return $self->registry->has_service($interface_name);
}

sub get_service {
  my ( $self, $package_name,$original_environment ) = @_;
  my $environment = $original_environment || $self->environment;

  # Check it is a registered service
  my $meta = $self->registry->get_service_definition($package_name,$environment);
  UnregisteredServiceException->throw( service => $package_name )
  unless $meta;

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
  my $service_factory = $self->_get_service_factory( $meta->builder );
  $service = $service_factory->build_service($meta);

  # Cache the service if it's a singleton
  if ( $meta->scope eq 'singleton' ) {
    $self->singletons->{ $meta->environment }->{$package_name} = $service;
  }

  return $service;
}

sub get_service_metadata {
  my ($self,$interface_name,$environment) = @_;

  return $self->registry->get_service_definition($interface_name,$environment);
}

sub _get_service_factory {
  my ( $self, $factory_type ) = @_;

  my $service_factory = $self->service_factories->{$factory_type};
  unless ($service_factory) {
    $service_factory = build_factory( $factory_type, $self );
    $self->service_factories->{$factory_type} = $service_factory;
  }

  return $service_factory;
}

1;
