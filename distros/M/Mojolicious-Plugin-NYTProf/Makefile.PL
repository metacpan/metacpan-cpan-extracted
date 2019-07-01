#!perl

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  MIN_PERL_VERSION => '5.10.1',
  NAME          => 'Mojolicious::Plugin::NYTProf',
  ABSTRACT_FROM => 'lib/Mojolicious/Plugin/NYTProf.pm',
  VERSION_FROM  => 'lib/Mojolicious/Plugin/NYTProf.pm',
  AUTHOR        => 'Lee Johnson <leejo@cpan.org>',
  LICENSE       => 'perl',
  PREREQ_PM => {
    'Devel::NYTProf'        => '6.06',
    'Mojolicious'           => '8.00',
    'File::Which'           => '1.09',
    'File::Temp'            => '0.22',
    'Time::HiRes'           => '1.9719',
    'File::Spec::Functions' => '3.30',
  },
  BUILD_REQUIRES => {
    'Test::More'               => 0,
    'Test::Exception'          => 0.32,
    'Algorithm::Combinatorics' => 0.27,
  },
  META_MERGE => {
    resources => {
      license    => 'http://dev.perl.org/licenses/',
      homepage   => 'https://metacpan.org/module/Mojolicious::Plugin::NYTProf',
      bugtracker => 'https://github.com/Humanstate/mojolicious-plugin-nytprof/issues',
      repository => 'https://github.com/Humanstate/mojolicious-plugin-nytprof'
    },
  },
  test => {
    TESTS => 't/*.t',
  },
);
