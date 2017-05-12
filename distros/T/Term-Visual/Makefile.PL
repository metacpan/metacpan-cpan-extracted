#!/usr/bin/perl

use ExtUtils::MakeMaker;

WriteMakefile
  ( NAME         => 'Term::Visual',
    AUTHOR       => 'Charles Ayres <lunartear@cpan.org>',
    ABSTRACT     => 'Curses split-terminal interface for applications.',
    VERSION_FROM => 'Visual.pm',
    PMLIBDIRS    => [ 'Visual' ],
    PREREQ_PM    => { POE          => 0.19,
                      Curses       => '',
                    },
    dist         => { COMPRESS     => 'gzip -9f',
                      SUFFIX       => 'gz',
                    },
  );
