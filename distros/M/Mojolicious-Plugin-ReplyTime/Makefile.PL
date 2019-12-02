use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Mojolicious::Plugin::ReplyTime',
  VERSION_FROM => 'lib/Mojolicious/Plugin/ReplyTime.pm',
  ABSTRACT     => 'Reply with a simple response of just the current time',
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
      bugtracker => {web => 'https://github.com/stefanadams/mojolicious-plugin-replytime/issues'},
      homepage   => 'https://stefan.adams.fm',
      license    => ['http://www.opensource.org/licenses/artistic-license-2.0'],
      repository => {
        type => 'git',
        url  => 'https://github.com/stefanadams/mojolicious-plugin-replytime.git',
        web  => 'https://github.com/stefanadams/mojolicious-plugin-replytime',
      },
      x_IRC => 'irc://irc.freenode.net/#mojo'
    },
  },
  PREREQ_PM    => {'Mojolicious' => '7.60'},
  EXE_FILES    => ['script/replytime'],
  test         => {TESTS => 't/*.t'}
);
