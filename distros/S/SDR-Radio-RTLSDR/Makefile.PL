use strict;

use ExtUtils::MakeMaker;

my %args = (
    NAME => 'SDR::Radio::RTLSDR',
    VERSION_FROM => 'lib/SDR/Radio/RTLSDR.pm',
    PREREQ_PM => {
      'common::sense' => 0,
      'AnyEvent' => 0,
      'Math::Int64' => '0.27_04',
    },
    LIBS => '-lrtlsdr -lpthread',
    OBJECT => '$(O_FILES)',
    DEFINE => '',
    LICENSE => 'perl',
    dist => {
      PREOP => 'pod2text $(VERSION_FROM) > $(DISTVNAME)/README',
    },
    META_MERGE => {
      resources => {
        repository => 'git://github.com/hoytech/SDR-Radio-RTLSDR.git',
        bugtracker => 'https://github.com/hoytech/SDR-Radio-RTLSDR/issues',
      },
    },
);

WriteMakefile(%args);
