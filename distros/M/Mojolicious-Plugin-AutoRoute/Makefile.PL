use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Mojolicious::Plugin::AutoRoute',
  VERSION_FROM => 'lib/Mojolicious/Plugin/AutoRoute.pm',
  AUTHOR       => 'A Good Programmer <nospam@cpan.org>',
  PREREQ_PM    => {'Mojolicious' => '2.98'},
  clean        => { FILES => 'Mojolicious-Plugin-AutoRoute-*' },
  test         => {TESTS => 't/*.t'}
);
