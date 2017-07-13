use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME             => 'Number::MuPhone',
  AUTHOR           => q{Clive Holloway <clive.holloway@gmail.com>},
  VERSION_FROM     => 'lib/Number/MuPhone.pm',
  ABSTRACT_FROM    => 'lib/Number/MuPhone.pm',
  LICENSE          => 'artistic_2',
  PL_FILES         => {},
  MIN_PERL_VERSION => 5.006,
  CONFIGURE_REQUIRES => {
    'ExtUtils::MakeMaker' => 0,
  },
  BUILD_REQUIRES => {
    'Test::More' => 0,
  },
  PREREQ_PM => {
    'YAML::XS' => '0.21',
    'Moo'      => '2.000000',
  },
  dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
  clean => { FILES => 'Number-MuPhone-*' },
  test => {
    TESTS => 't/tests/*/*/*.t t/tests/*/*/*/*.t t/tests/*/*/*/*/*.t',
  }
);
