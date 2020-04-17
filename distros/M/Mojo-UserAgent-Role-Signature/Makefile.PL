use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Mojo::UserAgent::Role::Signature',
  VERSION_FROM => 'lib/Mojo/UserAgent/Role/Signature.pm',
  ABSTRACT     => 'Automatically sign request transactions',
  AUTHOR       => 'Stefan Adams <sadams@cpan.org>',
  LICENSE      => 'artistic_2',
  META_MERGE   => {
    dynamic_config => 0,
    'meta-spec'    => {version => 2},
    no_index       => {
      directory => [qw(t)],
    },
    prereqs   => {runtime => {requires => {perl => '5.010001'}}},
    resources => {
      bugtracker => {web => 'https://github.com/stefanadams/Mojo-UserAgent-Role-Signature/issues'},
      homepage   => 'https://stefan.adams.fm',
      license    => ['http://www.opensource.org/licenses/artistic-license-2.0'],
      repository => {
        type => 'git',
        url  => 'https://github.com/stefanadams/Mojo-UserAgent-Role-Signature.git',
        web  => 'https://github.com/stefanadams/Mojo-UserAgent-Role-Signature',
      },
      x_IRC => 'irc://irc.freenode.net/#mojo'
    },
  },
  PREREQ_PM => {
    'Mojolicious' => '8.35',
    'Role::Tiny'  => '2.000001',
    'Class::Method::Modifiers' => '2.12',
  },
  test      => {TESTS => 't/*.t'}
);
