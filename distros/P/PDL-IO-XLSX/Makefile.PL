use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME          => 'PDL::IO::XLSX',
  AUTHOR        => 'KMX <kmx@cpan.org>',
  VERSION_FROM  => 'lib/PDL/IO/XLSX.pm',
  ABSTRACT_FROM => 'lib/PDL/IO/XLSX.pm',
  LICENSE       => 'perl',
  MIN_PERL_VERSION => '5.010',
  PREREQ_PM     => {
        'PDL'                 => '2.006', # we need: unpdl
        'PDL::DateTime'       => 0,
        'Archive::Zip'        => 0,
        'XML::Parser'         => 0,
        'Time::Moment'        => '0.12',  # we need: lenient ISO 8601 parsing
        'Exporter'            => '5.57',  # we need: use Exporter 'import';
  },
  BUILD_REQUIRES => {
        'PDL'                 => '2.006', # we need: unpdl
        'PDL::DateTime'       => 0,
        'Archive::Zip'        => 0,
        'XML::Parser'         => 0,
        'Time::Moment'        => '0.12',  # we need: lenient ISO 8601 parsing
        'Exporter'            => '5.57',  # we need: use Exporter 'import';
        'Test::More'          => '0.88',  # we need: done_testing()
        'Test::Number::Delta' => '1.06',  # versions before 1.06 have buggy relative mode
  },
  META_MERGE => {
      resources    => {
        repository => 'https://github.com/kmx/pdl-io-xlsx',
        bugtracker => 'https://github.com/kmx/pdl-io-xlsx/issues',
      },
  },
  dist => {
      ($^O eq 'MSWin32' ? (TAR => 'ptar', TARFLAGS => '-c -C -f') : (TARFLAGS => '--owner=0 --group=0 -cvf')),
      PREOP => 'perldoc -u lib/PDL/IO/XLSX.pm | pod2markdown > README.md',
  },
);
