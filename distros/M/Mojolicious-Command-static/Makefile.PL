use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Mojolicious::Command::static',
  VERSION_FROM => 'lib/Mojolicious/Command/static.pm',
  ABSTRACT     => 'Quickly serve static files',
  AUTHOR       => 'Stefan Adams <sadams@cpan.org>',
  LICENSE      => '',
  META_MERGE   => {
    dynamic_config => 0,
    'meta-spec'    => {version => 2},
    no_index       => {
      directory => [qw(t)],
    },
    prereqs   => {runtime => {requires => {perl => '5.010001'}}},
    resources => {
      bugtracker => {web => 'https://github.com/stefanadams/mojolicious-command-static/issues'},
      homepage   => 'https://stefan.adams.fm',
      license    => ['http://www.opensource.org/licenses/artistic-license-2.0'],
      repository => {
        type => 'git',
        url  => 'https://github.com/stefanadams/mojolicious-command-static.git',
        web  => 'https://github.com/stefanadams/mojolicious-command-static',
      },
      x_IRC => 'irc://irc.freenode.net/#mojo'
    },
  },
  PREREQ_PM    => {
    'Mojolicious' => '8.00',
    'List::MoreUtils' => '0.428',
  },
  test         => {TESTS => 't/*.t'}
);
