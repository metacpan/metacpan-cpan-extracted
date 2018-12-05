use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Mojolicious::Plugin::ACME::Command::acme::automate',
  VERSION_FROM => 'lib/Mojolicious/Plugin/ACME/Command/acme/automate.pm',
  AUTHOR       => 'Stefan Adams <sadams@cpan.org>',
  PREREQ_PM    => {'Mojolicious' => '8.04'},
  test         => {TESTS => 't/*.t'}
);
