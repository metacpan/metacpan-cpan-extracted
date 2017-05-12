#!/usr/bin/env perl
use ExtUtils::MakeMaker;

use lib qw(inc);
use Devel::CheckLib;

check_lib_or_exit(lib => ['X11', 'GL']);

WriteMakefile(
	NAME            => 'OpenGL::XScreenSaver',
	VERSION_FROM    => 'lib/OpenGL/XScreenSaver.pm',
	ABSTRACT_FROM   => 'lib/OpenGL/XScreenSaver.pm',
	LIBS            => '-lGL -lX11',
	LICENSE         => 'perl',
);
