use warnings;
use strict;
use Module::Build;

my $build = Module::Build->new(
	module_name          => 'Software::GenoScan',
	dist_abstract        => 'Software for computational discovery of miRNAs in genomic sequneces',
	license              => 'unrestricted',
	needs_compiler       => 1,
	build_requires       => {
		'Module::Build'        => '0.42',
		'ExtUtils::CBuilder'   => '0.21',
		'XSLoader'             => '0',
		'Exporter'             => '0'
	},
	configure_requires   => {
		'Module::Build'        => '0.42'
	},
	c_source                                => 'Software/GenoScan/src',
	xs_files => {
		'Software/GenoScan/Segmentor.xs'    => 'Software/GenoScan/Segmentor.xs'
	},
	pod_files => {
		'pod/GenoScan.pod'                  => 'pod/GenoScan.pod'
	}
);
$build->create_build_script();

