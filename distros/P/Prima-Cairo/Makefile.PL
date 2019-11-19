package MY;
use strict;
use ExtUtils::MakeMaker;
use ExtUtils::PkgConfig;
use Config;
use Prima::Config;

my %cairo_cfg = ExtUtils::PkgConfig->find ("cairo >= 1.0.0");

WriteMakefile(
	NAME		   => 'Prima::Cairo',
	VERSION_FROM	   => 'lib/Prima/Cairo.pm',
	MIN_PERL_VERSION   => '5.010',
	LICENSE            => 'BSD',
	PREREQ_PM	   => {
		'Prima'               => 1.42,
		'Cairo'               => 1.104,
	},
	CONFIGURE_REQUIRES => {
		'ExtUtils::PkgConfig' => 1.0,
		'Prima'               => 1.50,
	},
	ABSTRACT_FROM	   => 'lib/Prima/Cairo.pm',
	AUTHOR		   => 'Dmitry Karasik <dmitry@karasik.eu.org>',
	LIBS		   => "$Prima::Config::Config{libs} $cairo_cfg{libs}",
	DEFINE		   => "$Prima::Config::Config{define} $cairo_cfg{cflags}",
	INC                => "$Prima::Config::Config{inc} -Iinclude",
	OBJECT		   => "Cairo.o",
	META_MERGE	   => {
		resources  => {
			repository => 'http://github.com/dk/Prima-Cairo',
		},
		no_index   => {
			file	   => [qw(Makefile.PL)],
		},
	},
);
