use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Mojolicious::Plugin::PrometheusTiny',
  VERSION_FROM => 'lib/Mojolicious/Plugin/PrometheusTiny.pm',
  AUTHOR       => 'A Good Programmer <nospam@cpan.org>',
  PREREQ_PM    => {'Mojolicious' => '9.14'},
  test         => {TESTS => 't/*.t'}
);
