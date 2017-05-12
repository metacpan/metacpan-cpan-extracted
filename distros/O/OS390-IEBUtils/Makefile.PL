use strict;
use warnings;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.



WriteMakefile(
    NAME		=> 'OS390::IEBUtils',
    VERSION_FROM      	=> 'lib/OS390/IEBUtils.pm', # finds $VERSION
    PREREQ_PM 		=> {'Test::More' => 0},
    ABSTRACT_FROM	=> 'lib/OS390/IEBUtils.pm', # retrieve abstract from module
    AUTHOR		=> 'Paul Boin <paul@boin.org>',
    PL_FILES            => {},
    EXE_FILES           => [ 'bin/iebupdte','bin/iebptpch' ],
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'OS390-IEBUtils-*' },
);

