#!/usr/bin/env perl
use ExtUtils::MakeMaker;

use lib qw(inc);
use Devel::CheckLib;

check_lib_or_exit( lib => ['X11'] );

WriteMakefile(
    NAME          => 'SDLx::XScreenSaver',
    VERSION_FROM  => 'lib/SDLx/XScreenSaver.pm',
    ABSTRACT_FROM => 'lib/SDLx/XScreenSaver.pm',
    LIBS          => '-lX11',
    LICENSE       => 'perl',
    PREREQ_PM    => { 'SDL' => '2.501' },
);
