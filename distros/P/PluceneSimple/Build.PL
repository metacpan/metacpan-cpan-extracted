#!/usr/bin/perl -w

use strict;
use warnings;

use Module::Build;

shift(@ARGV)
	if $ARGV[0] && $ARGV[0] eq 'Build';    # accomodate with CPAN autoinstall
use Module::Build;

Module::Build->new(
	dist_name         => 'PluceneSimple',
	dist_version_from => 'lib/Plucene/Simple.pm',
	requires          => {
		'File::Spec::Functions' => '1.2',
		'Time::Piece'           => '1.08',
		'Time::Piece::Range'    => '1.0',
		'Plucene'               => '1.09',
	},
	build_requires => {
		'File::Find::Rule' => '0.10',
		'File::Path'       => '1.05',
		'File::Slurp'      => '2002.1031',
		'Test::Class'      => '0.03',
		'Test::Harness'    => '2.30',
	},
)->create_build_script;
