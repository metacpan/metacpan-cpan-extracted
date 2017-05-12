use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
	module_name        => 'SPOPSx::Tool::DateTime',
	license            => 'perl',
	create_makefile_pl => 'passthrough',
	create_readme      => 1,
	requires           => {
		'DateTime' => '0.29',
		'SPOPS'    => '0.87',
	},
	recommends         => {
		'DateTime::Format::Strptime' => '1.0601',
	},
);

$build->create_build_script;
