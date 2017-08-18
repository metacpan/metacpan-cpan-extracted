package MooseX::DIC::Configuration::Code;

use Moose;
with 'MooseX::DIC::Configuration';
with 'MooseX::DIC::Loggable';

use Module::Load 'load';
use List::Util 'reduce';
use MooseX::DIC::Configuration::Scanner::Injectable 'fetch_injectable_packages_from_path';
use aliased 'MooseX::DIC::PackageIsNotServiceException';
use aliased 'MooseX::DIC::FunctionalityNotImplementedException';
use aliased 'MooseX::DIC::ContainerConfigurationException';

sub get_services_metadata_from_path {
	my ($self,$paths) = @_;

	return
		map { $self->_get_meta_from_package($_) }
		fetch_injectable_packages_from_path( $paths );
}

sub _get_meta_from_package {
	my ($self,$package_name) = @_;

	# Make sure the the package is loaded
	load $package_name;

	# Check the package is an Injectable class
	my $injectable_role = 
		reduce {$a}
		grep { $_->{package} eq 'MooseX::DIC::Injectable' }
		$package_name->meta->calculate_all_roles_with_inheritance;
	PackageIsNotServiceException->throw( package => $package_name )
		unless defined $injectable_role;

	# Get the meta information from the injectable role
	my $meta = $package_name->get_service_metadata;
	ContainerConfigurationException->throw( message =>
		"The package $package_name is not propertly configured for injection"
	) unless $meta;

	return $meta;
}
