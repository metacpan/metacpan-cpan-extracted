use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Mojolicious::Plugin::CSPHeader',
  VERSION_FROM => 'lib/Mojolicious/Plugin/CSPHeader.pm',
  AUTHOR       => 'Luc Didry <ldidry@cpan.org>',
  ABSTRACT     => 'Mojolicious Plugin to add Content-Security-Policy header to every HTTP response.',
  PREREQ_PM    => {'Mojolicious' => '7.75'},
  LICENSE      => 'perl_5',
  test         => {TESTS => 't/*.t'},
  META_MERGE   => {
      "meta-spec" => { version => 2 },
      resources   => {
          repository => {
              type => 'git',
              url  => 'https://framagit.org/luc/mojolicious-plugin-cspheader.git',
              web  => 'https://framagit.org/luc/mojolicious-plugin-cspheader'
          }
      }
  }
);
