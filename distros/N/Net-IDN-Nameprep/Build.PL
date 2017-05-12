use 5.006;

use strict;
use utf8;

use Module::Build;

my $b = Module::Build->new(
	'module_name'	=> 'Net::IDN::Nameprep',
	'license'	=> 'perl',
	'dist_author'	=> 'Claus Färber <CFAERBER@cpan.org>',
	'dist_abstract' => 'A Stringprep Profile for Internationalized Domain Names (RFC 3491)', 

	'sign'		=> 1,
	'create_license' => 1,
	'create_makefile_pl' => 'traditional',

	'requires'	=> {
		'Unicode::Stringprep' => 1.1,
		'perl' => 5.008003, ## whatever U::S needs
	},
	'build_requires' => {
		'Test::More' => 0, 
		'Test::NoWarnings' => 0,
	},
	'no_index' => {
		'directory' => ['eg']
	},
        'meta_add' => {
	  'resources' => {
		'homepage' => 'http://search.cpan.org/dist/Net-IDN-Encode',
		'repository' => 'http://github.com/cfaerber/Net-IDN-Encode',
          },
	},
);

$b->create_build_script;
