use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME          => 'PDL::Finance::Talib',
  VERSION_FROM  => 'lib/PDL/Finance/Talib.pm',
  AUTHOR        => 'KMX <kmx@cpan.org>',
  ABSTRACT      => 'PDL interface to ta-lib library',
  LICENSE       => 'perl',
  PREREQ_PM     => {
        'PDL' => 2.006,
        'PDL::Finance::TA' => 0.008,
  },
  BUILD_REQUIRES     => {
        'PDL' => 2.006,
        'PDL::Finance::TA' => 0.008,
  },
  CONFIGURE_REQUIRES => {
        'PDL' => 2.006,
        'PDL::Finance::TA' => 0.008,
  },
  META_MERGE   => {
      resources    => {
          repository   => 'https://github.com/kmx/pdl-finance-talib',
      },
  },
  dist => {
      ($^O eq 'MSWin32' ? (TAR => 'ptar', TARFLAGS => '-c -C -f') : ()),
      PREOP => 'pod2text lib/PDL/Finance/Talib.pm > README',
  },
);
