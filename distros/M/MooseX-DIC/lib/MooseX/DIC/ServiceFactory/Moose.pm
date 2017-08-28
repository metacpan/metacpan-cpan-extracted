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

  my %dependencies = $self->build_dependencies_for($service_meta);

  my $service;
  try {
    $service = $service_meta->class_name->new(%dependencies);
  } catch {
    MooseX::DIC::ServiceCreationException->throw(
      message => "Error while building an injected service: $_" );
  };

  return $service;
}

sub build_dependencies_for {
  my ($self,$service_meta) = @_;

  my $class_meta = $service_meta->class_name->meta;

  # Build the to-be-injected dependencies of
  # the object
  my %dependencies = ();

  while(my ($name,$dependency) = each(%{$service_meta->dependencies})) {
    my $attribute = $class_meta->get_attribute($dependency->name);
    my $service_type = $attribute->type_constraint->name;

    if($self->container->has_service($service_type)) {

      if( $dependency->scope eq 'object' ) {
        $dependencies{ $dependency->name } = $self->container->get_service($service_type);
      } elsif( $dependency->scope eq 'request') {
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
          $dependency->name,
          sub {
            my ( $object, $value ) = @_;

            # This is only a setter. Trying to write is an error
            ContainerException->throw( message =>
              "A request-injected service accessor is read-only, it cannot be used as a setter"
            ) if $value;

            return $self->container->get_service($service_type);
          }
        );

        # We must pass a valid attribute value in case the attribute is required. It will never
        # get used, though.
        if( $attribute->is_required) {
          $dependencies{ $dependency->name } = $self->container->get_service($service_type);
        }
      } else {
        ContainerConfigurationException->throw( message => "Injection scope of dependencies can only
          be of type 'request' or 'object'" );
      }
    } else {
      UnregisteredServiceException->throw(service => $service_type )
        if ( $attribute->is_required );
    }
  }

  return %dependencies;

}

__PACKAGE__->meta->make_immutable;

1;
