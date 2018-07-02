use v5.10.1;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Sport::Analytics::NHL',
    license             => 'gnu',
    dist_author         => q{More Hockey Stats <contact@morehockeystats.com>},
    dist_version_from   => 'lib/Sport/Analytics/NHL.pm',
	dist_abstract       => 'Interface to the National Hockey League data',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => '0',
    },
    build_requires => {
        'Test::More' => '0',
    },
    requires => {
		boolean           => '0.28.4',
		Carp              => 0,
		'Data::Dumper'    => 0,
		'Date::Parse'     => 2.27,
		experimental      => 0.016,
		'File::Basename'  => 0,
		'File::Find'      => 0,
		'File::Path'      => 0,
		'Getopt::Long'    => 0,
		'JSON::XS'        => 2.27,
		'List::MoreUtils' => 0.22,
		'LWP::Simple'     => 5.837,
		POSIX             => 0,
		parent            => 0,
		Storable          => 0,
		'Tie::IxHash'     => 1.23,
		'Time::HiRes'     => 1.9721,
	},
	recommends => {
		'MongoDB'         => '1.8.1',
    },
    add_to_cleanup     => [ 'Sport-Analytics-NHL-*' ],
	script_files	 => {
		'scripts/scrape'	=> 'blib/scripts/scrape',
    },
);

$builder->create_build_script();
