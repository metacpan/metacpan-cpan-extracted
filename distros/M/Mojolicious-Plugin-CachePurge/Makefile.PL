use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Mojolicious::Plugin::CachePurge',
  VERSION_FROM => 'lib/Mojolicious/Plugin/CachePurge.pm',
  AUTHOR       => 'Stig Sandbeck Mathisen <ssm@fnord.no>',
  PREREQ_PM    => {'Mojolicious' => '4.99'},
  test         => {TESTS => 't/*.t'}
);
