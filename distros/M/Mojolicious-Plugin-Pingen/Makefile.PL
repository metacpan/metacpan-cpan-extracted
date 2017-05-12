use 5.010001;

use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Mojolicious::Plugin::Pingen',
  VERSION_FROM => 'lib/Mojolicious/Plugin/Pingen.pm',
  ABSTRACT     => 'Easily submit your documents to pingen for printing and mailing',
  AUTHOR       => 'Tobias Oetiker <tobi@oetiker.ch>',
  LICENSE      => 'gpl_3',
  PREREQ_PM    => {
    'Mojolicious' => '6.0',
    'IO::Socket::SSL' => '0',
  },
  META_MERGE   => {
    requires  => {perl => '5.010001'},
    resources => {
      license     => 'http://opensource.org/licenses/GPL-3.0',
      repository  => 'https://github.com/oetiker/mojolicious-plugin-pingen',
      bugtracker  => 'https://github.com/oetiker/mojolicious-plugin-pingen/issues'
    },
    no_index => {directory => ['t','setup']}
  },
  test => {TESTS => 't/*.t'}
);
