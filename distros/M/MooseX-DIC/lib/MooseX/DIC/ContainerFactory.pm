package MooseX::DIC::ContainerFactory;

use Moose;
with 'MooseX::DIC::Loggable';

use aliased 'MooseX::DIC::Container::DefaultImpl';
use aliased 'MooseX::DIC::Configuration::Code';
use aliased 'MooseX::DIC::Configuration::YAML';
use List::Util 'reduce';

has environment => (is => 'ro', isa => 'Str', default => 'default' );
has scan_path => ( is => 'ro', isa => 'ArrayRef[Str]', required => 1 );

sub build_container {
	my ($self) = @_;

	# Build the registry
	$self->logger->debug("Building the registry for the container...");
	my $registry = MooseX::DIC::ServiceRegistry->new;
	$self->_apply_config_to($registry);
	$self->logger->debug($registry->services_count." services registered");
	
	# Build the container
	my $container = DefaultImpl->new( environment => $self->environment, registry => $registry );

	$self->logger->debug("The container has been built from the registry");
	return $container;
}

sub _apply_config_to {
	my ($self,$registry) = @_;

	my @config_readers = ( Code->new, YAML->new );

	my $paths = reduce { $a." ".$b } @{$self->scan_path};
	$self->logger->debug("Fetching services from scanning inside $paths...");
	foreach my $reader (@config_readers) {
		my @services_metadata = $reader->get_services_metadata_from_path( $self->scan_path );
		foreach my $service_metadata (@services_metadata) {
			$registry->add_service_definition($service_metadata);
			$self->logger->debug("Service ".$service_metadata->class_name." was registered for interface ".$service_metadata->implements);
		}
	}
}

1;
