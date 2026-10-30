require 5.008005;

use strict;
use utf8;

use Module::Build;

my $b = Module::Build->new(
	'module_name'	=> 'Net::IDN::Encode',

	'license'	=> 'perl',
	'dist_author'	=> [ 'Claus Färber', 'Robert Rothenberg <perl@rhizomnic.com>', 'Paul Johnson <paul@pjcj.net>' ],
	'dist_abstract' => 'Internationalizing Domain Names in Applications (UTS #46)',

	'sign'		=> 0,
	'create_license' => 1,
	'create_makefile_pl' => 'traditional',

	'requires'	=> {
		'Unicode::Normalize' => 0,
		'perl'	=> 5.008005,
	},
	'test_requires' => {
		'Test::More' => 0,
		'Test::NoWarnings' => 0,
	},
	'meta_merge' => {
		'meta-spec' => { 'version' => 2 },
		'prereqs' => {
			'test' => {
				'requires' => {
					'Test::More' => 0,
					'Test::NoWarnings' => 0,
				},
				'recommends' => {
					'Test::LeakTrace' => 0,
				},
			},
		},
	},
	'needs_compiler' => undef,

	'PL_Files' => {
		'lib/Unicode/UTS46/_Mapping.PL'  => [
			 'lib/Net/IDN/UTS46/_Mapping.pm',
		],
		'lib/Unicode/UTS46/GenTests.PL'	 => [
			't/uts46_to_ascii.t',
			't/uts46_to_ascii-trans.t',
 			't/uts46_to_unicode.t',
		],
	},
	'no_index' => {
		'directory' => ['eg', 'data']
	},
	'meta_add' => {
		'resources' => {
			'homepage' => 'https://metacpan.org/release/Net-IDN-Encode',
			'bugtracker' => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Net-IDN-Encode',
			'repository' => 'http://github.com/robrwo/Net-IDN-Encode',
		},
	},
);

$b->create_build_script;
