use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Mojolicious::Plugin::BindSessionToIP',
  VERSION_FROM => 'lib/Mojolicious/Plugin/BindSessionToIP.pm',
  AUTHOR       => 'Viktor Turskyi <koorchik@cpan.org>',
  PREREQ_PM    => {
    'Mojolicious'                     => '3.90',
    'Mojolicious::Plugin::RemoteAddr' => '0.01'
  },
  test         => {TESTS => 't/*.t'}
);
