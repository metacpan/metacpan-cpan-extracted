#/usr/bin/env perl

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME'		=> 'Mojolicious::Plugin::CSSCompressor',
	'VERSION_FROM'	=> 'lib/Mojolicious/Plugin/CSSCompressor.pm',
	'PREREQ_PM'	=> {
		'CSS::Compressor'	=> 0,
		'Mojolicious'		=> 0,
	},
	'ABSTRACT_FROM'	=> 'lib/Mojolicious/Plugin/CSSCompressor.pm',
	'AUTHOR'	=> 'Simon Bertrang <janus@cpan.org>',
);

