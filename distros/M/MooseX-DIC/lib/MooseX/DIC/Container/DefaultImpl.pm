package MooseX::DIC::Container::DefaultImpl;

use MooseX::DIC::Types;
use aliased 'MooseX::DIC::UnregisteredServiceException';
use aliased 'MooseX::DIC::ServiceRegistry';
use aliased 'MooseX::DIC::PackageNotFoundException';
use aliased 'MooseX::DIC::ContainerException';
use MooseX::DIC::ServiceFactoryFactory 'build_factory';
use Module::Load;
use Try::Tiny;

use Moose;
with 'MooseX::DIC::Container';
with 'MooseX::DIC::Loggable';

has environment => ( is => 'ro', isa => 'Str', default => 'default' );
has registry => (is => 'ro', isa => 'MooseX::DIC::ServiceRegistry', required => 1);
has singletons => (is => 'ro', isa => 'HashRef[HashRef[Any]]', default => sub { { default => {} } });
has service_factories => ( is => 'ro', isa => 'HashRef[ServiceFactory]', default => sub { {} } );

sub has_service {
  my ( $self, $interface_name ) = @_;

  return $self->registry->has_service($interface_name);
}

sub build_class {
  my ($self,$package_name) = @_;

  $self->logger->debug("I'm going to build an instance of $package_name");
  try {
    load $package_name;
  } catch {
    $self->logger->debug("The instance could not be built for $package_name".
      " because the package could not be found: $_");
    PackageNotFoundException->throw(package_name=>$package_name);
  };

  ContainerException->throw(message => "The package $package_name is not a valid Moose class,"
    ." it cannot be instantiated") unless $package_name->can('meta');

  my %dependencies = ();
  foreach my $attribute ($package_name->meta->get_all_attributes){
    # We can only inject an attribute that defines a constraint
    if($attribute->type_constraint){
      my $service_type = $attribute->type_constraint->name;
      my $service = $self->get_service($service_type);

      unless($service) {
        $self->logger->error("Could not find service $service_type for mandatory attribute "
          .$attribute->name
          ." while building class $package_name");
        UnregisteredServiceException->throw(service=>$service_type) if($attribute->is_required);
      }
      $dependencies{$attribute->name} = $service;
    } else {
      if($attribute->is_required) {
        my $error = "Could not inject the required attribute "
          .$attribute->name
          ." of the class $package_name because it has no type constraint";
        $self->logger->error($error);

        ContainerException->throw(message => $error);
      }
    }
  }
  
  my $instance = 
    try {  $package_name->new(%dependencies) }
    catch {
      my $error = "Could not create an instance for package $package_name via "
        ."Moose constructor: $_";
      $self->logger->error($error);
      ContainerException->throw(message => $error);
    };
  
  return $package_name->new(%dependencies);
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
