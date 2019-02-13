use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Net::SharePoint::Basic',
    license             => 'perl_5',
    dist_author         => q{Roman Parparov <rparparov@vmware.com>},
    dist_version_from   => 'lib/Net/SharePoint/Basic.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
	test_requires => {
		'Test::Output' => 0.16,
	},
	requires => {
		Carp => 1.38,
		'Data::Dumper' => 2.161,
		'Data::UUID' => 1.203,
		Exporter => 5.63,
		'File::Basename' => 2.77,
		'File::Path' => 2.08,
		'Getopt::Long' => 2.38,
		'IO::Scalar' => '2.110',
		'JSON::XS' => 3.04,
		'LWP::UserAgent' => 5.835,
		POSIX => 1.17,
		Storable => '2.20',
		'URI::Escape' => 3.31,
		experimental => 0.016,
	},
	script_files => {
		'scripts/sp-client'         => 'blib/scripts/sp-client',

	},
    add_to_cleanup     => [ 'Net-SharePoint-Basic-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
