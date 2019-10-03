use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Mojo::UserAgent::Role::PromiseClass',
  VERSION_FROM => 'lib/Mojo/UserAgent/Role/PromiseClass.pm',
  AUTHOR       => 'Roger Crew <wrog@cpan.org>',
  PREREQ_PM    => {
      'Mojolicious' => '8.23',
      'Role::Tiny' => '2.000001',
      'Class::Method::Modifiers' => 0,
  },
  TEST_REQUIRES => {'Test::Fatal'=> 0 },
  test         => {TESTS => 't/*.t'},
  LICENSE => 'perl_5'
);
