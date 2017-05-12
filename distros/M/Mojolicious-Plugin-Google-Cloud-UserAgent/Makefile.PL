use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Mojolicious::Plugin::Google::Cloud::UserAgent',
  VERSION_FROM => 'lib/Mojolicious/Plugin/Google/Cloud/UserAgent.pm',
  AUTHOR       => 'Scott Wiersdorf <scott@perlcode.org>',
  PREREQ_PM    => {'Mojolicious' => '6.64',
                   'Mojo::JWT::Google' => '0.05',},
  test         => {TESTS => 't/*.t'}
);
