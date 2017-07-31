package MooseX::DIC::ServiceFactory::Factory;

use Moose;
with 'MooseX::DIC::ServiceFactory';
use namespace::autoclean;

use aliased 'MooseX::DIC::ServiceCreationException';
use Try::Tiny;

has container =>
    ( is => 'ro', does => 'MooseX::DIC::Container', required => 1 );

sub build_service {
    my ( $self, $service_meta ) = @_;

    # The factory itself must be a non-dependency object
    my $service;
    try {
        my $factory = $service_meta->class_name->new;
        $service = $factory->build_service(
            $service_meta->implements,
            $self->container
        );
    }
    catch {
        ServiceCreationException->throw( message => "The factory "
                . $service_meta->class_name
                . " could not be created: $_" );
    };

    return $service;
}

__PACKAGE__->meta->make_immutable;

1;
