use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Mojolicious::Plugin::DebugDumperHelper',
  VERSION_FROM => 'lib/Mojolicious/Plugin/DebugDumperHelper.pm',
  AUTHOR       => 'A Good Programmer <nospam@cpan.org>',
  PREREQ_PM    => {'Mojolicious' => '6.11'},
  test         => {TESTS => 't/*.t'}
);
