use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Mojolicious::Plugin::RussianPost',
  VERSION_FROM => 'lib/Mojolicious/Plugin/RussianPost.pm',
  AUTHOR       => 'Kostya Ten <kostya@cpan.org>',
  PREREQ_PM    => {'Mojolicious' => '7.06'},
  LICENSE      => 'artistic_2',
  test => {TESTS => 't/*.t t/*/*.t'}
);
