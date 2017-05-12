use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME          => 'PDL::IO::CSV',
  AUTHOR        => 'KMX <kmx@cpan.org>',
  VERSION_FROM  => 'lib/PDL/IO/CSV.pm',
  ABSTRACT_FROM => 'lib/PDL/IO/CSV.pm',
  LICENSE       => 'perl',
  MIN_PERL_VERSION => '5.008',
  PREREQ_PM     => {
        'PDL'          => '2.006', # we need: unpdl
        'Text::CSV_XS' => 0,
        'Exporter'     => '5.57',  # we need: use Exporter 'import';
  },
  BUILD_REQUIRES => {
        'PDL'                 => '2.006', # we need: unpdl
        'Text::CSV_XS'        => 0,
        'Exporter'            => '5.57',  # we need: use Exporter 'import';
        'Test::More'          => '0.88',  # we need: done_testing()
        'Test::Number::Delta' => '1.06',  # versions before 1.06 have buggy relative mode
  },
  META_MERGE => {
      prereqs => {
        runtime => {
          recommends => {
            'PDL::DateTime' => 0,
            'Time::Moment'  => '0.12',  # we need: lenient ISO 8601 parsing
            'Time::Piece'   => 0,
          },
        },
      },
      resources    => {
        repository => 'https://github.com/kmx/pdl-io-csv',
        bugtracker => 'https://github.com/kmx/pdl-io-csv/issues',
      },
  },
  dist => {
      ($^O eq 'MSWin32' ? (TAR => 'ptar', TARFLAGS => '-c -C -f') : (TARFLAGS => '--owner=0 --group=0 -cvf')),
      PREOP => 'perldoc -u lib/PDL/IO/CSV.pm | pod2markdown > README.md',
  },
);
