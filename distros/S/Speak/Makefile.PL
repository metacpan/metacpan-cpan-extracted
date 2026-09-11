use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile (
  NAME               => 'Speak',
  AUTHOR             => q{Andrew DeFaria <Andrew@DeFaria.com>},
  VERSION_FROM       => 'lib/Speak.pm',
  ABSTRACT_FROM      => 'lib/Speak.pm',
  LICENSE            => 'gpl_2',
  PL_FILES           => {},
  MIN_PERL_VERSION   => '5.006',
  CONFIGURE_REQUIRES => {
    'ExtUtils::MakeMaker' => '0',
  },
  BUILD_REQUIRES => {
    'Test::More' => '0',
  },
  PREREQ_PM => {
    'Clipboard'     => '0',
    'HTTP::Request' => '0',
    'JSON::PP'      => '0',
    'LWP::UserAgent' => '0',
    'URI::Escape'   => '0',
  },
  dist      => {COMPRESS => 'gzip -9f', SUFFIX => 'gz',},
  clean     => {FILES    => 'Speak-*'},
  EXE_FILES => ['bin/speak', 'bin/say'],
);
