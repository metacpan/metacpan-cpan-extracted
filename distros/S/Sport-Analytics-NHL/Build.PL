use v5.10.1;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
	module_name        => 'Sport::Analytics::NHL',
	license            => 'gnu',
	dist_author        => q{More Hockey Stats <contact@morehockeystats.com>},
	dist_version_from  => 'lib/Sport/Analytics/NHL.pm',
	dist_abstract      => 'Interface to the National Hockey League data',
	release_status     => 'stable',
	configure_requires => {
		'Module::Build' => '0',
	},
	build_requires     => {
		'Test::More' => '0',
	},
	requires           => {
		boolean             => '0.28.4',
		Carp                => 0,
		'Data::Dumper'      => 0,
		'Date::Calc'        => 6.4,
		'Date::Format'      => 2.24,
		'Date::Parse'       => 2.27,
		Encode              => 2.49,
		experimental        => 0.016,
		'File::Basename'    => 0,
		'File::Copy'        => 0,
		'File::Find'        => 0,
		'File::Path'        => 0,
		'Getopt::Long'      => 0,
		'HTML::TreeBuilder' => 5.03,
		'JSON'              => '2.90',
		if		    => 0.05,
		'List::MoreUtils'   => 0.22,
		'List::Util'        => 1,
		'LWP::Simple'       => 5.837,
		'LWP::Protocol::https' => 5.837,
		'Module::Pluggable' => 5.2,
		parent              => 0,
		POSIX               => 0,
		Storable            => 0,
		'Text::Unidecode'   => '1.30',
		'Tie::IxHash'       => 1.23,
		'Time::HiRes'       => 1.9721,
		'Time::Local'       => 1.25,
		'Try::Tiny'         => 0.27,
	},
	recommends         => {
		'BSON::OID' => 'v1.8.1',
		'MongoDB' => 'v1.6.0',
		'File::Touch' => 0,
	},
	add_to_cleanup     => [ 'Sport-Analytics-NHL-*' ],
	script_files       => {
		'scripts/scrape'           => 'blib/scripts/scrape',
		'scripts/compile'          => 'blib/scripts/compile',
		'scripts/compile-schedule' => 'blib/scripts/compile-schedule',
		'scripts/merge'          => 'blib/scripts/merge',
		'scripts/merge-schedule' => 'blib/scripts/merge-schedule',
		'scripts/normalize'          => 'blib/scripts/normalize',
		'scripts/normalize-schedule' => 'blib/scripts/normalize-schedule',
		'scripts/test-consistency' => 'blib/scripts/test-consistency',
	},
);

$builder->create_build_script();
