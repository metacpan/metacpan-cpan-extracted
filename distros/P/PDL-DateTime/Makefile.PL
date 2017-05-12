use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use Config;

warn "FATAL: Your perl does not support 64bit integers!\n" and exit(0) if $Config{ivsize} < 8;
 
WriteMakefile(
  NAME          => 'PDL::DateTime',
  VERSION_FROM  => 'lib/PDL/DateTime.pm',
  AUTHOR        => 'KMX <kmx@cpan.org>',
  ABSTRACT_FROM => 'lib/PDL/DateTime.pod',
  LICENSE       => 'perl',
  PREREQ_PM => {
        'PDL'          => '2.014', # we need longlong-double fix
        'Time::Moment' => '0.12',  # we need lenient ISO 8601 parsing
  },
  BUILD_REQUIRES => {
        'PDL'                 => '2.014',
        'Time::Moment'        => '0.12',
        'Test::More'          => '0.88',  # we need: done_testing()
        'Test::Number::Delta' => '1.06',  # versions before 1.06 have buggy relative mode
  },
  MIN_PERL_VERSION => '5.010', # same as PDL 2.013+
  META_MERGE => {
      resources    => {
          repository => 'https://github.com/kmx/pdl-datetime',
          bugtracker => 'https://github.com/kmx/pdl-datetime/issues',
      },
  },
  dist => {
      ($^O eq 'MSWin32' ? (TAR => 'ptar', TARFLAGS => '-c -C -f') : (TARFLAGS => '--owner=0 --group=0 -cvf')),
      PREOP => 'perldoc -u lib/PDL/DateTime.pod | pod2markdown > README.md',
  },
);
