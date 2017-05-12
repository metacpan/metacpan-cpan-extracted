#!/usr/bin/perl

use ExtUtils::MakeMaker;

WriteMakefile(
		'MAKEFILE'=> 'Makefile',
		'VERSION_FROM' => 'lib/Module/InstalledVersion.pm',
		'NAME'    => 'Module::InstalledVersion', 
		'PREREQ_PM'  => { # e.g., Module::Name => 1.1
                    'Test::More'  => 0.18,
                    'File::Spec'  => 0.82,
		},
                EXE_FILES => [ 'modversion' ],
	      );
