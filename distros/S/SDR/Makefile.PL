use strict;

use ExtUtils::MakeMaker;

my %args = (
    NAME => 'SDR',
    VERSION_FROM => 'lib/SDR.pm',
    PREREQ_PM => {
      'common::sense' => 0,
      'AnyEvent' => 0,
      'PDL' => 0,
      'PDL::DSP::Fir::Simple' => 0,
    },
    LICENSE => 'perl',
    dist => {
      PREOP => 'pod2text $(VERSION_FROM) > $(DISTVNAME)/README',
    },
    META_MERGE => {
      resources => {
        repository => 'git://github.com/hoytech/SDR.git',
        bugtracker => 'https://github.com/hoytech/SDR/issues',
      },
    },
);

WriteMakefile(%args);
