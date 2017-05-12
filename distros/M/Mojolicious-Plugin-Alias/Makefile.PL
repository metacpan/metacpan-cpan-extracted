use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Mojolicious::Plugin::Alias',
    VERSION_FROM => 'lib/Mojolicious/Plugin/Alias.pm',
    AUTHOR       => 'Dotan Dimet <dotan@corky.net>',
    PREREQ_PM => { 'Mojolicious' => '4.85' },
    LICENSE      => 'artistic_2',
    ABSTRACT     => 'Mojolicious plugin to serve static files from aliased paths',
    META_MERGE   => {
    requires  => {perl => '5.010001'},
    resources => {
      license     => 'http://www.opensource.org/licenses/artistic-license-2.0',
      repository  => 'http://github.com/dotandimet/mojolicious-plugin-alias',
      bugtracker  => 'http://github.com/dotandimet/mojolicious-plugin-alias/issues'
    },
    no_index => {directory => ['t']}
  },
    test => { TESTS => 't/*.t' }
);
