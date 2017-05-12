use 5.006;

use strict;
use utf8;

use Module::Build;

my $b = Module::Build->new(
	'module_name'	=> 'Net::IDN::IDNA2003',

	'license'	=> 'perl',
	'dist_author'	=> 'Claus Färber <CFAERBER@cpan.org>',
	'dist_abstract' => 'Internationalizing Domain Names in Applications (2003) (RFC 3490)',

	'sign'		=> 1,
	'create_license' => 1,
	'create_makefile_pl' => 'traditional',

	'requires'	=> {
		'Net::IDN::Punycode' => 1,
		'Net::IDN::Nameprep' => 1.1,
	},
	'build_requires' => {
		'Test::More' => 0, 
		'Test::NoWarnings' => 0,
	},
	'no_index' => {
		'directory' => ['eg']
	},
	'resources' => {
		'homepage' => 'http://search.cpan.org/dist/Net-IDN-Encode',
		'repository' => 'http://github.com/cfaerber/Net-IDN-Encode',
	},
);

$b->create_build_script;
