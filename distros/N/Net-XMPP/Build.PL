use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
	module_name   => 'Net::XMPP',
	license       => 'lgpl',
	dist_author   => 'Darian Anthony Patrick <dapatrick@cpan.org>',
	dist_abstract => 'XMPP Support Library',

	configure_requires => {
		'Module::Build' => '0.360300',
	},

	build_requires => {
		'LWP::Online'   => '1.07',
		'Test::More'    => '0.92',
		'YAML::Tiny'    => '1.41',
	},

	requires => {
		'perl'         => 'v5.8.0',
		'Authen::SASL' => '2.12',
		'Digest::SHA'  => '0',
		'XML::Stream'  => '1.24',
		'Scalar::Util' => '0',
	},

	sign               => 1,
	create_license     => 1,
	create_makefile_pl => 'small',
	meta_merge => {
		'resources' => {
			'bugtracker' => 'https://github.com/dap/Net-XMPP/issues',
			'repository' => 'https://github.com/dap/Net-XMPP',
		}
	},
);

$build->create_build_script();
