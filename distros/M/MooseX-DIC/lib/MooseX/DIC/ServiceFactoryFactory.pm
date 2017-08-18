package MooseX::DIC::ServiceFactoryFactory;

require Exporter;
@ISA       = qw/Exporter/;
@EXPORT_OK = qw/build_factory/;

use aliased 'MooseX::DIC::ContainerException';
use Module::Load;
use Try::Tiny;

sub build_factory {
    my ( $factory_type, $container ) = @_;

    my $service_factory;
	try {
        load "MooseX::DIC::ServiceFactory::$factory_type";

        $service_factory = "MooseX::DIC::ServiceFactory::$factory_type"
            ->new( container => $container );

    } catch {
		ContainerException->throw(
			message => "Could not build the service factory $factory_type: $_" );
	};

    return $service_factory;
}

1;
