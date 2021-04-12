;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  NAME       => 'OpenAPI::Generator',
  AUTHOR       => q{Anton Fedotov <tosha.fedotov.2000@gmail.com>},
  VERSION_FROM   => 'lib/OpenAPI/Generator.pm',
  ABSTRACT_FROM  => 'lib/OpenAPI/Generator.pm',
  LICENSE      => 'artistic_2',
  MIN_PERL_VERSION => '5.014',
  META_MERGE => {
    dynamic_config => 0,
    'meta-spec' => { version => 2 },
    resources => {
      bugtracker => {web => 'https://github.com/doojonio/OpenAPI-Generator/issues'},
      license => ['http://www.opensource.org/licenses/artistic-license-2.0'],
      repository => {
        type => 'git',
        url => 'https://github.com/doojonio/OpenAPI-Generator.git',
        web => 'https://github.com/doojonio/OpenAPI-Generator',
      },
    }
  },
  CONFIGURE_REQUIRES => {
    'ExtUtils::MakeMaker' => '0',
  },
  TEST_REQUIRES => {
    'Test::More' => '0',
  },
  PREREQ_PM => {},
  dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
  clean => { FILES => 'OpenAPI-Generator-*' },
);

# Compatibility with old versions of ExtUtils::MakeMaker
unless (eval { ExtUtils::MakeMaker->VERSION('6.64'); 1 }) {
  my $test_requires = delete $WriteMakefileArgs{TEST_REQUIRES} || {};
  @{$WriteMakefileArgs{PREREQ_PM}}{keys %$test_requires} = values %$test_requires;
}

unless (eval { ExtUtils::MakeMaker->VERSION('6.55_03'); 1 }) {
  my $build_requires = delete $WriteMakefileArgs{BUILD_REQUIRES} || {};
  @{$WriteMakefileArgs{PREREQ_PM}}{keys %$build_requires} = values %$build_requires;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION('6.52'); 1 };
delete $WriteMakefileArgs{MIN_PERL_VERSION}
  unless eval { ExtUtils::MakeMaker->VERSION('6.48'); 1 };
delete $WriteMakefileArgs{LICENSE}
  unless eval { ExtUtils::MakeMaker->VERSION('6.31'); 1 };

WriteMakefile(%WriteMakefileArgs);
