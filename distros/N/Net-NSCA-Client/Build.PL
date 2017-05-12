use 5.008;
use strict;
use warnings 'all';

use Module::Build 0.31;

my $build = Module::Build->new(
	module_name => 'Net::NSCA::Client',
	license     => 'perl',
	dist_author => 'Douglas Christopher Wilson <doug@somethingdoug.com>',

	meta_merge => {
		resources => {
			homepage   => 'http://github.com/dougwilson/perl5-net-nsca-client/',
			repository => 'git://github.com/dougwilson/perl5-net-nsca-client.git',
		},
		no_index => {
			directory => [qw/inc t xt/],
		},
	},

	# Modules that are required for this script
	configure_requires => {
		'Module::Build' => '0.31',
	},

	# Modules that are required for tests in t/
	build_requires => {
		'Data::Section'   => 0,
		'MIME::Base64'    => '2.00',
		'Test::Class'     => '0.33',
		'Test::Command'   => '0.08',
		'Test::Fatal'     => 0,
		'Test::More'      => '0.94',
		'Test::Requires'  => '0.02',
		'Test::TCP'       => '1.03',
	},

	# Modules that are required
	requires => {
		'perl'                      => '5.008001',
		'Const::Fast'               => 0,
		'Convert::Binary::C'        => '0.74',
		'Data::Rand::Obscure'       => '0.020',
		'Data::Validate::Domain'    => '0.02',
		'Digest::CRC'               => 0,
		'English'                   => 0,
		'IO::Socket::INET'          => 0,
		'List::MoreUtils'           => 0,
		'Moose'                     => '0.89',
		'MooseX::Clone'             => 0,
		'MooseX::StrictConstructor' => '0.08',
		'MooseX::Types'             => '0.08',
		'MooseX::Types::PortNumber' => 0,
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
