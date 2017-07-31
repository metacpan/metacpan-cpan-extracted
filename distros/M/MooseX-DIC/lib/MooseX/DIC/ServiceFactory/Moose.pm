package MooseX::DIC::ServiceFactory::Moose;

use Moose;
with 'MooseX::DIC::ServiceFactory';
use namespace::autoclean;

use aliased 'MooseX::DIC::UnregisteredServiceException';
use aliased 'MooseX::DIC::ContainerConfigurationException';
use aliased 'MooseX::DIC::ServiceCreationException';
use Try::Tiny;

has container =>
    ( is => 'ro', does => 'MooseX::DIC::Container', required => 1 );

sub build_service {
    my ( $self, $service_meta ) = @_;

    # Build the to-be-injected dependencies of
    # the object
    my %dependencies = ();

    my $class_meta = $service_meta->class_name->meta;

    foreach my $attribute ( $class_meta->get_all_attributes ) {
        if ( $attribute->does('MooseX::DIC::Injected') ) {
            my $service_type = $attribute->type_constraint->name;

            if ( $attribute->scope eq 'object' ) {
                my $dependency = $self->container->get_service($service_type);
                UnregisteredServiceException->throw(
                    service => $service_type )
                    unless $dependency;
                $dependencies{ $attribute->name } = $dependency;
            } elsif ( $attribute->scope eq 'request' ) {

                # It is a configuration error to ask for a request-injection of
                # a singleton object. It may indicate a misconception or a config
                # typo.
                my $scope = $self->container->get_service_meta($service_type)
                    ->scope;
                ContainerConfigurationException->throw( message =>
                        "A singleton-scoped service cannot be injected into a request-injected attribute"
                ) if $scope eq 'singleton';

                $attribute->remove_accessors;
                $class_meta->add_method(
                    $attribute->name,
                    sub {
                        my ( $object, $value ) = @_;

                        # This is only a setter. Trying to write is an error
                        ContainerException->throw( message =>
                                "A request-injected service accessor is read-only, it cannot be used as a setter"
                        ) if $value;

                        my $service
                            = $self->container->get_service($service_type);
                        UnregisteredServiceException->throw(
                            service => $service_type )
                            unless $service;

                        return $service;
                    }
                );

                # We must pass a valid attribute value in case the attribute is required. It will never
                # get used, though.
                $dependencies{ $attribute->name }
                    = $self->container->get_service($service_type);
            } else {
                ContainerConfigurationException->throw( message =>
                        "An injection point can only be of type 'object' or 'request'"
                );
            }
        }
    }

    my $service;
    try {
        $service = $service_meta->class_name->new(%dependencies);
    }
    catch {
        MooseX::DIC::ServiceCreationException->throw(
            message => "Error while building an injected service: $_" );
    };

    return $service;
}

__PACKAGE__->meta->make_immutable;

1;
