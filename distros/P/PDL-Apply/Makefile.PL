use strict;
use warnings;
use ExtUtils::MakeMaker;
use Config;

WriteMakefile(
  NAME          => 'PDL::Apply',
  VERSION_FROM  => 'lib/PDL/Apply.pm',
  AUTHOR        => 'KMX <kmx@cpan.org>',
  ABSTRACT_FROM => 'lib/PDL/Apply.pm',
  LICENSE       => 'perl',
  PREREQ_PM => {
        'PDL'          => '2.006', # we need: unpdl
        'Exporter'     => '5.59',  # we need: use Exporter 'import';
  },
  BUILD_REQUIRES => {
        'PDL'                 => '2.006', # we need: unpdl
        'Exporter'            => '5.59',  # we need: use Exporter 'import';
        'Test::More'          => '0.88',  # we need: done_testing()
        'Test::Number::Delta' => '1.06',  # versions before 1.06 have buggy relative mode
  },
  META_MERGE => {
      resources    => {
          repository   => 'https://github.com/kmx/pdl-apply',
      },
  },
  dist => {
      ($^O eq 'MSWin32' ? (TAR => 'ptar', TARFLAGS => '-c -C -f') : ()),
      PREOP => 'perldoc -u lib/PDL/Apply.pm | pod2markdown > README.md',
  },
);
