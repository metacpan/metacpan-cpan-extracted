use 5.016;

use strict;
use warnings;
use utf8;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'SQL::Abstract::Pg',
  VERSION_FROM => 'lib/SQL/Abstract/Pg.pm',
  ABSTRACT     => 'PostgreSQL features for SQL::Abstract',
  AUTHOR       => 'Sebastian Riedel <sri@cpan.org>',
  LICENSE      => 'artistic_2',
  META_MERGE   => {
    dynamic_config => 0,
    'meta-spec'    => {version   => 2},
    no_index       => {directory => ['examples', 't']},
    prereqs        => {runtime   => {requires => {perl => '5.016'}}},
    resources      => {
      bugtracker => {web => 'https://github.com/mojolicious/sql-abstract-pg/issues'},
      homepage   => 'https://mojolicious.org',
      license    => ['http://www.opensource.org/licenses/artistic-license-2.0'],
      repository => {
        type => 'git',
        url  => 'https://github.com/mojolicious/sql-abstract-pg.git',
        web  => 'https://github.com/mojolicious/sql-abstract-pg',
      },
      x_IRC => {url => 'irc://chat.freenode.net/#mojo', web => 'https://webchat.freenode.net/#mojo'}
    },
  },
  PREREQ_PM => {'SQL::Abstract' => '2.0'},
  test      => {TESTS           => 't/*.t t/*/*.t'}
);
