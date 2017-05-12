use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Mojolicious::Plugin::StaticLog',
  VERSION_FROM => 'lib/Mojolicious/Plugin/StaticLog.pm',
  AUTHOR       => 'Frank Carnovale <frankc@cpan.org>',
  PREREQ_PM    => {'Mojolicious' => '6.44'},
  test         => {TESTS => 't/*.t'}
);
