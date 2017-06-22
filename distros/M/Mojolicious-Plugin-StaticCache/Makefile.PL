use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Mojolicious::Plugin::StaticCache',
  VERSION_FROM => 'lib/Mojolicious/Plugin/StaticCache.pm',
  ABSTRACT     => 'Mojolicious::Plugin::StaticCache - Mojolicious Plugin which add a Control-Cache header to each static file served by Mojolicious.',
  AUTHOR       => 'Luc Didry <ldidry@cpan.org>',
  PREREQ_PM    => {'Mojolicious' => '7.33'},
  LICENSE      => 'perl_5',
  test         => {TESTS => 't/*.t'}
);
