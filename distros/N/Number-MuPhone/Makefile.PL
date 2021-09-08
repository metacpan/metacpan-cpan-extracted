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
  EXE_FILES        => ['script/perl-muphone-build-data'],
  CONFIGURE_REQUIRES => {
    'ExtUtils::MakeMaker' => 0,
  },
  BUILD_REQUIRES => {
    'Test::More' => 0,
  },
  PREREQ_PM => {
    'Data::Dumper'    => '2.0',
    'File::Fetch'     => '0.5',
    'LWP::Simple'     => '6.0',
    'Moo'             => '2.000000',
    'Types::Standard' => '1.0',
    'XML::Simple'     => '2.0',
  },
  dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
  clean => { FILES => 'Number-MuPhone-*' },
  test => {
    TESTS => 't/*.t',
  }
);
