package SkewHeapMakeMaker;

use strict;
use warnings;
use ExtUtils::MakeMaker;

my $OPTIMIZE = $ENV{DEBUG} ? '-g -O1' : ($ENV{OPTIMIZE} || '-O2');

sub MY::postamble {
  return <<EOS;

misc : readme distcheck manifest

release : test misc dist
\tcpan-upload \$(DISTVNAME).tar.gz

EOS
}

WriteMakefile(
  NAME             => 'SkewHeap',
  AUTHOR           => 'Jeff Ober <sysread@fastmail.fm>',
  VERSION_FROM     => "lib/SkewHeap.pm",
  ABSTRACT_FROM    => 'README.pod',
  LICENSE          => 'perl_5',
  MIN_PERL_VERSION => '5.010',
  PREREQ_PRINT     => 1,
  OPTIMIZE         => $OPTIMIZE,

  META_MERGE => {
    'meta-spec' => {
      version => 2,
    },

    resources => {
      homepage => "https://github.com/sysread/SkewHeap",

      bugtracker => {
        web => "https://github.com/sysread/SkewHeap/issues"
      },

      repository => {
        type => "git",
        url  => "https://github.com/sysread/SkewHeap.git",
        web  => "https://github.com/sysread/SkewHeap"
      }
    },
  },

  MAN3PODS => {
    'README.pod' => "blib/man3/SkewHeap.3",
  },

  test => {
    TESTS => 't/*',
  },

  clean => {
    FILES => "*.bak SkewHeap-*.tar.gz",
  },

  BUILD_REQUIRES => {
    'ExtUtils::MakeMaker' => '6.63_03',
  },

  TEST_REQUIRES => {
    'Test2::V0'       => 0,
    'Test::LeakTrace' => '0.16',
  },

  PREREQ_PM => {
    'Carp'     => 0,
    'Exporter' => 0,
    'parent'   => 0,
  },
);

1;
