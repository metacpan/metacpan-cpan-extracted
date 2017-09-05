use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME          => 'Statistics::Distribution::Generator',
  AUTHOR        => q{Paul Bennett <paul.w.bennett@gmail.com>},
  VERSION_FROM  => 'lib/Statistics/Distribution/Generator.pm',
  ABSTRACT_FROM => 'lib/Statistics/Distribution/Generator.pm',
  (LICENSE => 'artistic_2')x!!($ExtUtils::MakeMaker::VERSION >= 6.31),
  PL_FILES => {},
  PREREQ_PM => {
    'Exporter' => '0',
    'List::AllUtils' => '0',
    'overload' => '0',
  },
  TEST_REQUIRES => { 
    'Test::More' => 0, 
    'Statistics::Descriptive' => '0',
    ('Test::Pod::Coverage' => '1.08')x!!(-d '.git'),
    ('Test::Pod' => '1.22')x!!(-d '.git'),
  },
  (MIN_PERL_VERSION => '5.10.0')x!!($ExtUtils::MakeMaker::VERSION >= 6.48),
  (META_MERGE => {
    "meta-spec" => { version => 2 },
    resources => {
      repository => {
          type => 'git',
          url => 'git://github.com/PWBENNETT/Statistics-Distribution-Generator.git',
          web => 'https://github.com/PWBENNETT/Statistics-Distribution-Generator',
      },
    },
  })x!!($ExtUtils::MakeMaker::VERSION >= 6.46),
  dist => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
  clean => { FILES => 'Statistics-Distribution-Generator-*' },
);
