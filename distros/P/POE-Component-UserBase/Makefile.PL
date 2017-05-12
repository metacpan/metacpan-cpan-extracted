#!/usr/bin/perl
# $Id: Makefile.PL,v 1.2 2000/11/26 02:33:43 jgoff Exp $

use ExtUtils::MakeMaker;

WriteMakefile
  ( NAME         => 'POE::Component::UserBase',
    AUTHOR       => 'Jeff Goff <jgoff@blackboard.com>',
    ABSTRACT     => ( 'POE component for handling user authentication' .
                      'with varying methods.'
                    ),
    VERSION_FROM => 'UserBase.pm',

    PM           => { 'UserBase.pm' => '$(INST_LIBDIR)/UserBase.pm' },
    PREREQ_PM    => { POE      => 0.11,
                      Storable => 1.0,
                    },
    dist         => { COMPRESS => 'gzip -9f',
                      SUFFIX   => 'gz',
                    },
  );
