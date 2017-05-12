
use strict;
use warnings;

use Module::Build;

die "OS unsupported" if $^O ne 'linux';

my $build = new Module::Build(
	module_name => 'Net::Link',
	license => 'artistic_2',
	requires => {
		perl => '5.8.8',
		'Net::Interface' => '0.08',
	},
);

$build->create_build_script;
