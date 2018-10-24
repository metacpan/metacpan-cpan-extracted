use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Mojolicious::Plugin::SpectreCss',
  VERSION_FROM => 'lib/Mojolicious/Plugin/SpectreCss.pm',
  AUTHOR       => 'CandyAngel <candyangel@electricjungle.org>',
  PREREQ_PM    => {'Mojolicious' => '8.03'},
  test         => {TESTS => 't/*.t'}
);
