use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Mojolicious::Plugin::CoverDb',
  VERSION_FROM => 'lib/Mojolicious/Plugin/CoverDb.pm',
  ABSTRACT     => 'Mojolicious::Plugin::CoverDb - Mojolicious Plugin which exposes a directory (designed for a cover_db dir, created by Devel::Cover).',
  AUTHOR       => 'Luc Didry <ldidry@cpan.org>',
  PREREQ_PM    => {'Mojolicious' => '8.58'},
  LICENSE      => 'perl_5',
  test         => {TESTS => 't/*.t'}
);
