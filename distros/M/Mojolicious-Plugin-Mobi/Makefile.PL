use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Mojolicious::Plugin::Mobi',
  VERSION_FROM => 'lib/Mojolicious/Plugin/Mobi.pm',
  AUTHOR       => 'Valcho Nedelchev <kumcho@vulcho.com>',
  PREREQ_PM    => {'Mojolicious' => '4.50'},
  test         => {TESTS => 't/*.t'}
);
