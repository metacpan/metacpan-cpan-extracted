use 5.008;
use strict;
use warnings 'all';

use Module::Build 0.31;

my $build = Module::Build->new(
	module_name => 'Net::SAJAX',
	license     => 'perl',
	dist_author => 'Douglas Christopher Wilson <doug@somethingdoug.com>',

	meta_merge => {
		resources => {
			homepage   => 'http://github.com/dougwilson/perl5-net-sajax/',
			repository => 'git://github.com/dougwilson/perl5-net-sajax.git',
		},
		no_index => {
			directory => [qw/inc t xt/],
		},
	},

	# Modules that are required for this script
	configure_requires => {
		'Module::Build' => '0.31',
	},

	# Module that are required for tests in t/
	build_requires => {
		'Test::Fatal'      => 0,
		'Test::MockObject' => 0,
		'Test::More'       => '0.41',
		'Test::Requires'   => '0.02',
		'URI::Escape'      => 0,
	},

	# Module that are required
	requires => {
		'perl'                      => '5.008003',
		'Carp'                      => 0,
		'Class::Load'               => 0,
		'English'                   => 0,
		'HTTP::Request::Common'     => '5.814',
		'JE'                        => '0.033',
		'List::MoreUtils'           => 0,
		'LWP::UserAgent'            => '5.819',
		'Moose'                     => '0.77',
		'MooseX::StrictConstructor' => '0.08',
		'MooseX::Types::URI'        => '0.02',
		'URI'                       => '1.22',
		'URI::QueryParam'           => 0,
		'namespace::clean'          => '0.04',
	},

	# The above requirements are static
	dynamic_config => 0,

	# Enable tests to be in multi-level directories
	recursive_test_files => 1,

	# Create a LICENSE file
	create_license => 1,

	# Sign the distribution
	sign => 1,

	test_files => 't/*.t xt/*.t',
);

$build->create_build_script;
