# Makefile.PL
#
# $Id: Makefile.PL,v 1.1 2009/01/10 16:17:59 drhyde Exp $

use 5.008004;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Palm::SMS',
    META_MERGE => {
        license => 'other',
        resources => {
	    repository => 'https://github.com/DrHyde/perl-modules-Palm-SMS',
	    bugtracker => 'https://github.com/DrHyde/perl-modules-Palm-SMS/issues'
        }
    },
    VERSION_FROM      => 'lib/Palm/SMS.pm',
    EXE_FILES         => ['bin/smsdump'],
    PREREQ_PM         => {
        'Palm::Raw'      => 0,
        'Palm::PDB'      => 0,
        'Date::Format'   => 0,
        'Getopt::Long'   => 0,
        'Pod::Usage'     => 0,
        'File::Basename' => 0,
        'Text::Wrap'     => 0,
        'Test::More'     => 0,
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Palm/SMS.pm', # retrieve abstract from module
       AUTHOR         => 'Lorenzo Cappelletti <lorenzo.cappelletti@email.it>')
     : ()),
);
