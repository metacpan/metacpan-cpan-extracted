use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Mojo::Promise::Role::Repeat',
  VERSION_FROM => 'lib/Mojo/Promise/Role/Repeat.pm',
  AUTHOR       => 'Roger Crew <wrog@cpan.org>',
  PREREQ_PM    => {
      'Mojolicious' => '8.23',
      'Role::Tiny' => '2.000001',
  },
  test         => {TESTS => 't/*.t'},
  LICENSE => 'perl_5'
);
