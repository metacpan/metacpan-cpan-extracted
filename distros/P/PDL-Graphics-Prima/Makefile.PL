use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME => 'PDL::Graphics::Prima',
  VERSION_FROM => 'lib/PDL/Graphics/Prima.pm',
  LICENSE => 'perl',
  MIN_PERL_VERSION => '5.012', # Prima is minimum 5.12
  CONFIGURE_REQUIRES => {
    'ExtUtils::MakeMaker' => 0,
  },
  PREREQ_PM => {
    'PDL::Drawing::Prima' => '0.15',
    'PDL' => '2.4.0',
    Prima => '1.67',
  },
  TEST_REQUIRES => {
    'Test::More' => '0.88',
  },
  META_MERGE => {
    "meta-spec" => { version => 2 },
    dynamic_config => 0,
    resources => {
      x_IRC => 'irc://irc.perl.org/#graphql-perl',
      repository => {
        type => 'git',
        url => 'git@github.com:PDLPorters/PDL-Graphics-Prima.git',
        web => 'https://github.com/PDLPorters/PDL-Graphics-Prima',
      },
      bugtracker  => {
        web => 'https://github.com/PDLPorters/PDL-Graphics-Prima/issues',
      },
    },
  },
);
