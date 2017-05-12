#!/usr/bin/perl -w

use strict;

use ExtUtils::MakeMaker;

WriteMakefile(
	NAME         => 'MooseX::Compile',
	VERSION_FROM => 'lib/MooseX/Compile/Base.pm',
	INSTALLDIRS  => 'site',
	SIGN         => 1,
	PL_FILES     => { },
	PREREQ_PM    => {
		'Test::use::ok' => 0,
        'Moose' => '0.34',
        'Data::Visitor' => '0.15',
        'PadWalker' => 0,
        'Class::Inspector' => 0,
        'Data::Dump' => 0,
        'Devel::INC::Sorted' => 0,
	},
);

