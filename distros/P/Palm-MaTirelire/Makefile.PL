use ExtUtils::MakeMaker; # -*- coding: utf-8 -*-
use utf8;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME           => 'Palm::MaTirelire',
    VERSION	   => '1.14',
    PREREQ_PM      => {
	'Palm::PDB'	   => '1.015',
	'Palm::StdAppInfo' => '1.014',
    },
    ABSTRACT	   => 'Superclass handler for Palm MaTirelire databases',
    AUTHOR         => 'Maxime Soulé <max@ma-tirelire.net>',
);
