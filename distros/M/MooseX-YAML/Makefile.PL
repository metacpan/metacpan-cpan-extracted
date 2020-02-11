#!/usr/bin/perl -w

use strict;

use ExtUtils::MakeMaker;

WriteMakefile(
	NAME         => 'MooseX::YAML',
	ABSTRACT     => 'DWIM loading of Moose objects from YAML',
	AUTHOR       => 'Yuval Kogman <nothingmuch@woobling.org>',
	LICENSE      => 'perl',
	VERSION_FROM => 'lib/MooseX/YAML.pm',
	INSTALLDIRS  => 'site',
	PL_FILES     => { },
	PREREQ_PM    => {
		'Test::use::ok' => 0,
		'YAML' => 0,
		'MooseX::Blessed::Reconstruct' => '0.03',
		'Sub::Exporter' => '0.982',
		'namespace::clean' => 0,
	},
);

