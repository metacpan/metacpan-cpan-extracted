#!/usr/bin/perl

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'         => 'Template::Plugin::JSON::Escape',
	'VERSION_FROM' => 'lib/Template/Plugin/JSON/Escape.pm',
	'PREREQ_PM' => {
		'Template'   => '2.20',
		'Test::More' => '0',
		'JSON'       => '2.12',
	},
    'INSTALLDIRS' => 'site',
    'EXE_FILES'   => [],
    'PL_FILES'    => {}
);

unless ( eval { require JSON::XS } ) {
warn <<WARN
JSON::XS is reccomended, you should probably install it for better performance.
WARN
}
