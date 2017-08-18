package MooseX::DIC::ServiceFactory::Moose;

use Moose;
with 'MooseX::DIC::ServiceFactory';
use namespace::autoclean;

with 'MooseX::DIC::Loggable';

use aliased 'MooseX::DIC::UnregisteredServiceException';
use aliased 'MooseX::DIC::ContainerConfigurationException';
use aliased 'MooseX::DIC::ServiceCreationException';
use Try::Tiny;

has container => ( is => 'ro', does => 'MooseX::DIC::Container', required => 1 );

sub build_service {
  my ( $self, $service_meta ) = @_;

  # Build the to-be-injected dependencies of
  # the object
  my %dependencies = ();

  my $class_meta = $service_meta->class_name->meta;

  foreach my $attribute ( $class_meta->get_all_attributes ) {
    my $service_type = $attribute->type_constraint->name;

    if( $self->container->has_service($service_type) ) {
      $self->logger->trace("Injecting a $service_type service into ".($service_meta->class_name)."'s ".($attribute->name)." attribute");

      # The container has the service, so try to inject it.
      if ( not(exists($attribute->{scope})) || $attribute->scope eq 'object' ) {
        # If no injection point is defined, just use the default object scope
        my $dependency = $self->container->get_service($service_type);
        UnregisteredServiceException->throw(
          service => $service_type )
        unless $dependency;
        $dependencies{ $attribute->name } = $dependency;
      } elsif ( $attribute->scope eq 'request' ) {

        # It is a configuration error to ask for a request-injection of
        # a singleton object. It may indicate a misconception or a config
        # typo.
        my $attribute_service_meta = $self->container->get_service_metadata($service_type);
        ContainerConfigurationException->throw( message =>
          "A singleton-scoped service cannot be injected into a request-injected attribute"
        ) if $attribute_service_meta->scope eq 'singleton';

        # Replace the getter with a custom proxy function
        $attribute->remove_accessors;
        $class_meta->add_method(
          $attribute->name,
          sub {
            my ( $object, $value ) = @_;

            # This is only a setter. Trying to write is an error
            ContainerException->throw( message =>
              "A request-injected service accessor is read-only, it cannot be used as a setter"
            ) if $value;

            my $service = $self->container->get_service($service_type);
            UnregisteredServiceException->throw(service => $service_type )
              unless $service;

            return $service;
          }
        );

        # We must pass a valid attribute value in case the attribute is required. It will never
        # get used, though.
        if( $attribute->is_required) {
          $dependencies{ $attribute->name } = $self->container->get_service($service_type);
        }
      } 
    } else {
      # The container does not have a service for the constraint type
      # of the attribute. If the attribute is not required, just ignore
      # it (but log this fact). Otherwise, it is an error.
      
      $self->logger->warning("While building ".($service_meta->class_name)." dependencies, the container did not find a matching service for $service_type");
      if( $attribute->is_required ) {
        ServiceCreationException->throw(message=>"A service cannot be created if a required attribute has no mapping on the registry");
      }
    }
  } 

  my $service;
  try {
    $service = $service_meta->class_name->new(%dependencies);
  } catch {
    MooseX::DIC::ServiceCreationException->throw(
      message => "Error while building an injected service: $_" );
  };

  return $service;
}

__PACKAGE__->meta->make_immutable;

1;
