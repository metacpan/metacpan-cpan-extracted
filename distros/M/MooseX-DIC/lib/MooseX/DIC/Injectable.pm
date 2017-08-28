package MooseX::DIC::Injectable;

use MooseX::DIC::Types;
use aliased 'MooseX::DIC::Configuration::ServiceMetadata';
use MooseX::DIC::Configuration::ServiceMetadata::Dependency 'from_attribute';

use MooseX::Role::Parameterized;

parameter scope       => ( isa => 'ServiceScope', default => 'singleton' );
parameter environment => ( isa => 'Str',          default => 'default' );
parameter implements => ( isa => 'Str', predicate => 'has_implements' );
parameter qualifiers => ( isa => 'ArrayRef[Str]',  default => sub { [] } );
parameter builder    => ( isa => 'ServiceBuilder', default => 'Moose' );

role {
  my ( $p, %args ) = @_;

  # If this injectable is a factory, it must provide the build_service
  # method so that the container can use it.
  # The build_service will receive:
  # - the service metadata object
  # - the container
  # - injection point metadata
  if ( $p->builder eq 'Factory' ) {
    requires 'build_service';
  }


  # Inject in the package metadata the mooseX metadata
  $args{consumer}->add_method(
    get_service_metadata => sub {
      # Prepare dependencies metadata
      my %dependencies =
        map { ($_->name => from_attribute($_)) }
        $args{consumer}->get_all_attributes;

      return ServiceMetadata->new(
        class_name  => $args{consumer}->{package},
        scope       => $p->scope,
        environment => $p->environment,
        qualifiers  => $p->qualifiers,
        implements  => $p->implements,
        builder     => $p->builder,
        dependencies => \%dependencies
      );
    }
  );
};

1;
