package MooseX::DIC::Configuration::YAML;

use Moose;
with 'MooseX::DIC::Configuration';

use YAML::XS;
use File::Spec::Functions qw/splitpath rel2abs/;
use File::Slurp;
use Try::Tiny;
use MooseX::DIC::Configuration::Scanner::FileConfig 'fetch_config_files_from_path';
use aliased 'MooseX::DIC::ContainerConfigurationException';
use aliased 'MooseX::DIC::ServiceMetadata';
use Module::Load 'load';

sub get_services_metadata_from_path {
	my ($self,$paths) = @_;

	return
		map { build_services_metadata_from_config_file($_) }
		fetch_config_files_from_path($paths);
}

sub build_services_metadata_from_config_file {
	my ($config_file) = @_;

	ContainerConfigurationException->throw(message=>"Specified config file $config_file not found")
		unless -f $config_file;
	
	# Parse YAML config file
	my $raw_config;
	try {
		my $config_content = read_file($config_file);
		$raw_config = Load $config_content;
	} catch {
		ContainerConfigurationException->throw(message=>"Error while loading config file $config_file: $_");
	};

	# Load included files, to be applied later
	my @included_files = ();
	push @included_files,@{$raw_config->{include}} if exists($raw_config->{include});

	my @services_metadata = ();
	while(my ($interface,$implementators) = each(%{$raw_config->{mappings}})) {

    #Make sure the interface package is loaded
    load $interface;

    # The config specs allows the implementators of an interface to be specified
    # either as a string which defines a simple implementator with default values, 
    # or as a hash of full implementators wich are key-value service metadata
    # definitions.

    if(ref($implementators) eq 'HASH') {
      while( my ($implementator,$definition) = each(%$implementators)) {
        
        # Make sure the implementator package is loaded
        load $implementator;

        my $service_metadata = ServiceMetadata->new(
          class_name => $implementator,
          implements => $interface,
          (exists($definition->{scope})? (scope => $definition->{scope}):()),
          (exists($definition->{builder})? (builder => $definition->{builder}):()),
          (exists($definition->{environment})? (environment => $definition->{environment}):()),
          (exists($definition->{qualifiers})? (qualifiers => $definition->{qualifiers}):())
        );
        push @services_metadata, $service_metadata;
      }
		} else {
      # Make sure the implementator package is loaded
      load $implementators;

      my $service_metadata = ServiceMetadata->new(
				class_name => $implementators,
				implements => $interface,
			);
			push @services_metadata, $service_metadata;
    }
		
	}

	# Load include files
	push @services_metadata,
		map { build_services_metadata_from_config_file($_) }
		map { normalize_included_file_path($config_file,$_) }
		@included_files;

	return @services_metadata;
}

sub normalize_included_file_path {
	my ($original_file,$included_file) = @_;
	my ($volume,$path,$file) = splitpath($original_file);

	return rel2abs($included_file,$path);
}

1;
