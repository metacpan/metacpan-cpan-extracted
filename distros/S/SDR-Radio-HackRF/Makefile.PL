use strict;

use ExtUtils::MakeMaker;

my %args = (
    NAME => 'SDR::Radio::HackRF',
    VERSION_FROM => 'lib/SDR/Radio/HackRF.pm',
    PREREQ_PM => {
      'common::sense' => 0,
      'AnyEvent' => 0,
      'Math::Int64' => '0.27_04',
    },
    LIBS => '-lhackrf',
    OBJECT => '$(O_FILES)',
    DEFINE => '',
    LICENSE => 'perl',
    dist => {
      PREOP => 'pod2text $(VERSION_FROM) > $(DISTVNAME)/README',
    },
    META_MERGE => {
      resources => {
        repository => 'git://github.com/hoytech/SDR-Radio-HackRF.git',
        bugtracker => 'https://github.com/hoytech/SDR-Radio-HackRF/issues',
      },
    },
);

WriteMakefile(%args);
