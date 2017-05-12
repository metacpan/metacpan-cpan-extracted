# Makefile.PL for Time::SZTime module -*- perl -*-

use ExtUtils::MakeMaker;

WriteMakefile (
    NAME		=> 'Time::SZTime',
    DISTNAME		=> 'SZTime',
    ABSTRACT		=> 'Unixtime to SZTime convertor',
    AUTHOR		=> 'Sebastian Schwarz <sjsz@cpan.org>',
    VERSION_FROM	=> 'SZTime.pm',
    dist		=> { COMPRESS => 'gzip', SUFFIX => 'gz' }
);

