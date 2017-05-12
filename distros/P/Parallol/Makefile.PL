use 5.010001;

use strict;
use warnings;

use ExtUtils::MakeMaker;

my ($mm) = $ExtUtils::MakeMaker::VERSION =~ /^([^_]+)/;

WriteMakefile(
  NAME         => 'Parallol',
  VERSION_FROM => 'lib/Parallol.pm',
  ABSTRACT     => 'Because parallel requests should be as fun as parallololololol!',
  AUTHOR       => 'Magnus Holm <judofyr@gmail.com>',

  ($mm < 6.3002 ? () : ('LICENSE' => 'artistic_2')),

  PREREQ_PM => {
    'Mojolicious' => 0,
  },
  test => {TESTS => 't/*.t'}
);

