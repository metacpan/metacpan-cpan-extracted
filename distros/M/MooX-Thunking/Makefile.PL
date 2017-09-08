use 5.014;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME             => 'MooX::Thunking',
  AUTHOR           => q{Ed J <etj@cpan.org>},
  VERSION_FROM     => 'lib/MooX/Thunking.pm',
  ABSTRACT_FROM    => 'lib/MooX/Thunking.pm',
  LICENSE          => 'artistic_2',
  MIN_PERL_VERSION => '5.014',
  CONFIGURE_REQUIRES => {
    'ExtUtils::MakeMaker' => '0',
  },
  TEST_REQUIRES => {
    'Test::More' => '0.88', # done_testing
    'Test::Exception' => '0.42',
  },
  PREREQ_PM => {
    'Moo' => '0',
    'Type::Tiny' => '0',
  },
  clean => { FILES => 'MooX-Thunking-*' },
  META_MERGE => {
    "meta-spec" => { version => 2 },
    dynamic_config => 0,
    resources => {
      x_IRC => 'irc://irc.perl.org/#graphql-perl',
      repository => {
        type => 'git',
        url => 'git@github.com:mohawk2/moox-thunking.git',
        web => 'https://github.com/mohawk2/moox-thunking',
      },
      license => [ 'http://dev.perl.org/licenses/' ],
    },
    prereqs => {
      develop => {
        requires => {
          'Test::CheckManifest' => '0.9',
          'Test::Pod::Coverage' => '1.08',
          'Test::Pod' => '1.22',
        },
      },
    },
  },
);
