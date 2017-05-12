use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Mojolicious::Plugin::RemoteAddr',
  VERSION_FROM => 'lib/Mojolicious/Plugin/RemoteAddr.pm',
  AUTHOR       => 'Viktor Turskyi <koorchik@cpan.org>',
  PREREQ_PM    => {'Mojolicious' => '3.90'},
  test         => {TESTS => 't/*.t'},
  META_MERGE   => {
    resources => {
      repository => 'https://github.com/koorchik/Mojolicious-Plugin-RemoteAddr',
    },
  },
);
