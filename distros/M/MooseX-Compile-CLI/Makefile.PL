#!/usr/bin/perl -w

use strict;

use ExtUtils::MakeMaker;

WriteMakefile(
	NAME         => 'MooseX::Compile::CLI',
	VERSION_FROM => 'lib/MooseX/Compile/CLI.pm',
	INSTALLDIRS  => 'site',
	SIGN         => 1,
	PL_FILES     => { },
    EXE_FILES    => [ "script/mxcompile" ],
	PREREQ_PM    => {
		'Test::use::ok' => 0,
        'MooseX::Compile' => 0,
        'MooseX::App::Cmd' => "0.02",
        'Prompt::ReadKey' => "0.02",
        'Tie::RefHash' => 0,
        'Path::Class' => 0,
        'MooseX::Types::Path::Class' => 0,
        'MooseX::AttributeHelpers' => 0,
	},
);

