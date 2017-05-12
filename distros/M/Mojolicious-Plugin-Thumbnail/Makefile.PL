use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  ABSTRACT => 'Use Imager in Mojolicious',
  AUTHOR => 'Andrey Gatitskiy <gatitskiy@cpan.org>',
  NAME         => 'Mojolicious::Plugin::Thumbnail',
  VERSION_FROM => 'lib/Mojolicious/Plugin/Thumbnail.pm',
  PREREQ_PM    => {
    'Mojolicious' => 0,
    'Imager'      => 0,
  },
  test         => {TESTS => 't/*.t'}
);
