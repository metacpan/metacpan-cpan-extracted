#!/usr/bin/perl

use 5.008008;
use ExtUtils::MakeMaker;

unless( $^O eq 'linux' ) {
    die "This module only works on Linux, with inotify\n";
}

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'POEx::Inotify',
    VERSION_FROM      => 'lib/POEx/Inotify.pm', # finds $VERSION
    LICENSE           => 'perl',
    PREREQ_PM         => {
            'POE'       => 1.284,
            'POE::Session::PlainCall'       => 0.0300,
            'Linux::Inotify2' => 1,
            'File::Path' => 2.08,
            'Data::Dump' => 1,
            Carp         => 1
        },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/POEx/Inotify.pm', # retrieve abstract from module
       AUTHOR         => 'Philip Gwyn <gwyn -at- cpan.org>') : ()),
);
