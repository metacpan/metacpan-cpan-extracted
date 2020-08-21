use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Mojolicious::Plugin::CoverDb',
  VERSION_FROM => 'lib/Mojolicious/Plugin/CoverDb.pm',
  ABSTRACT     => 'Mojolicious::Plugin::CoverDb - Mojolicious Plugin which exposes a directory (designed for a cover_db dir, created by Devel::Cover).',
  AUTHOR       => 'Luc Didry <ldidry@cpan.org>',
  CONFIGURE_REQUIRES => {
      'ExtUtils::MakeMaker' => '6.48'
  },
  MIN_PERL_VERSION => 5.020,
  PREREQ_PM    => {'Mojolicious' => '8.58'},
  LICENSE      => 'perl_5',
  test         => {TESTS => 't/*.t'},
  META_MERGE   => {
      "meta-spec" => { version => 2 },
      resources   => {
          bugtracker => {
              web  => 'https://framagit.org/luc/mojolicious-plugin-coverdb/issues'
          },
          repository => {
              type => 'git',
              url  => 'https://framagit.org/luc/mojolicious-plugin-coverdb.git',
              web  => 'https://framagit.org/luc/mojolicious-plugin-coverdb'
          }
      }
  }
);
