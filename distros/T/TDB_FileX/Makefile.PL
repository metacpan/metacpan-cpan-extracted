use ExtUtils::MakeMaker;

use Canary::Stability TDB_FileX => 1, 5.010;

# FYI, ExtUtils::MakeMaker adds recognised command line args to this
# hash too.  eg: perl Makefile.PL INC=-I/path LIBS='-L/other/path -ltdb'
WriteMakefile(
    'NAME'		=> 'TDB_FileX',
    'VERSION_FROM'	=> 'TDB_FileX.pm', # finds $VERSION
    PREREQ_PM => {
       common::sense => 3,
    },
    CONFIGURE_REQUIRES => { "ExtUtils::MakeMaker" => 6.52, "Canary::Stability" => 0 },
    ABSTRACT_FROM => 'TDB_FileX.pm', # retrieve abstract from module
    AUTHOR     => 'Angus Lees <gus@inodes.org>',
    #'CONFIGURE'         => \&configure,
    'LIBS'		=> ['-ltdb'],
    #'OPTIMIZE'		=> '-g -Wall',
    'clean'		=> {FILES => "t/test.tdb"},
);

