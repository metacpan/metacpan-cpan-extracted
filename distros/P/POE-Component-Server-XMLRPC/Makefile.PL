#!/usr/bin/perl
# $Id: Makefile.PL,v 1.1.1.1 2003/03/20 17:05:13 mah Exp $

use strict;
use lib qw(./mylib);
use ExtUtils::MakeMaker;

# Ensure that ./CHANGES exists.
open(CHANGES, ">>CHANGES");
close CHANGES;

# Write that makefile.
WriteMakefile
  ( NAME         => 'POE::Component::Server::XMLRPC',
    AUTHOR       => 'Mark A. Hershberger <mah@everybody.org>',
    ABSTRACT     => 'POE component for providing XMLRPC services.',
    VERSION_FROM => 'XMLRPC.pm',
    PM           => { 'XMLRPC.pm' => '$(INST_LIBDIR)/XMLRPC.pm',
                    },
    PREREQ_PM    => { 'POE'                          => 0.22,
                      'XMLRPC::Lite'                 => 0.28,
                      'POE::Component::Server::HTTP' => 0.02,
                    },
    dist         =>
    { COMPRESS   => 'gzip -9f',
      SUFFIX     => 'gz',
      PREOP      => ( 'cvs-log.perl | ' .
                      'tee ./$(DISTNAME)-$(VERSION)/CHANGES > ./CHANGES'
                    ),
    },
  );
