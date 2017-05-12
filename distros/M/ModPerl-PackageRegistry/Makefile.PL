#!/usr/bin/perl

use strict;
use warnings;
use 5.006;
use ExtUtils::MakeMaker;
use Apache::TestMM qw(test clean);

# accept the configs from command line
Apache::TestMM::filter_args();
Apache::TestMM::generate_script('t/TEST');

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'ModPerl::PackageRegistry',
    VERSION_FROM      => 'lib/ModPerl/PackageRegistry.pm', # finds $VERSION
    PREREQ_PM         => {
    },
    clean             => { FILES => "@{ clean_files() }" },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/ModPerl/PackageRegistry.pm', # retrieve abstract from module
       AUTHOR         => 'Tyler MacDonald <japh@crackerjack.net>') : ()),
);

sub clean_files {
    return [ 't/TEST' ];
}
