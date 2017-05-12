#!/usr/bin/perl

use ExtUtils::MakeMaker;
WriteMakefile(
	'NAME'=>'TXTCOD',
	'VERSION_FROM'=>'lib/TXTCOD.pm',
	'NORECURS'=>'1',
	'PMLIBDIRS'=>['lib']
);