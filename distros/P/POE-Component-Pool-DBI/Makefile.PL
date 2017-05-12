#!/usr/bin/perl

use strict;
use warnings FATAL => "all";
use ExtUtils::MakeMaker;

# Touch CHANGES so it exists.
open CHANGES, ">>CHANGES" and close CHANGES;

WriteMakefile
  ( NAME         => 'POE::Component::Pool::DBI',
    AUTHOR       => 'Scott S. McCoy (tag@cpan.org)',
    ABSTRACT     => 'A POE Component for managing Boss/Worker DBI pools',
    VERSION_FROM => 'DBI.pm',

    PREREQ_PM    => {
        POE      => 0.30,
        'POE::Component::Pool::Thread'      => 0.015,
        threads  => 1.03,
    },

    dist         =>
    { DIST_DEFAULT => "tardist",
	  COMPRESS   => 'gzip -9f',
      SUFFIX     => 'gz',
      PREOP      => ( 'svn log | ' .
                      'tee ./$(DISTNAME)-$(VERSION)/CHANGES > ./CHANGES'
                    ),
    },
  );
