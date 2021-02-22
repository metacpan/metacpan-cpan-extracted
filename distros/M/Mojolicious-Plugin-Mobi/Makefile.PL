use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Mojolicious::Plugin::Mobi',
  VERSION_FROM => 'lib/Mojolicious/Plugin/Mobi.pm',
  AUTHOR       => 'Valcho Nedelchev <weby@cpan.org>',
  PREREQ_PM    => {'Mojolicious' => '9.0'},
  test         => {TESTS => 't/*.t'}
);
