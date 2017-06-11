use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Mojolicious::Plugin::PgURLHelper',
  VERSION_FROM => 'lib/Mojolicious/Plugin/PgURLHelper.pm',
  ABSTRACT     => 'Mojolicious::Plugin::PgURLHelper - Mojolicious Plugin to easily create PostgreSQL URLs suitable for Mojo::Pg or Minion::Backend::Pg',
  AUTHOR       => 'Luc Didry <ldidry@cpan.org>',
  PREREQ_PM    => {'Mojolicious' => '7.23'},
  LICENSE      => 'perl_5',
  test         => {TESTS => 't/*.t'}
);
