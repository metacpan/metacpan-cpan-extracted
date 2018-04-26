use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Mojolicious::Plugin::GzipStatic',
  VERSION_FROM => 'lib/Mojolicious/Plugin/GzipStatic.pm',
  AUTHOR       => 'Luc Didry <ldidry@cpan.org>',
  ABSTRACT     => 'Mojolicious Plugin to compress the static files before serving them.',
  PREREQ_PM    => {
      'Mojolicious' => '7.75',
      'IO::Compress::Gzip' => 0
  },
  LICENSE      => 'perl_5',
  test         => {TESTS => 't/*.t'},
  META_MERGE   => {
      "meta-spec" => { version => 2 },
      resources   => {
          repository => {
              type => 'git',
              url  => 'https://framagit.org/luc/mojolicious-plugin-gzipstatic.git',
              web  => 'https://framagit.org/luc/mojolicious-plugin-gzipstatic'
          }
      }
  }
);
