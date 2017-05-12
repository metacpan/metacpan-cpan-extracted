#!perl

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME          => 'Mojolicious::Plugin::OAuth2::Server',
  ABSTRACT_FROM => 'lib/Mojolicious/Plugin/OAuth2/Server.pm',
  VERSION_FROM  => 'lib/Mojolicious/Plugin/OAuth2/Server.pm',
  AUTHOR        => 'Lee Johnson <leejo@cpan.org>',
  LICENSE       => 'perl',
  PREREQ_PM => {
    'Mojolicious'  => '5.37',
    'Net::OAuth2::AuthorizationServer'  => '0.14',
    'Carp'            => 0,
  },
  BUILD_REQUIRES => {
    'FindBin'         => 0,
    'File::Find'      => 0,
    'Test::More'      => 0,
    'Test::Deep'      => 0.113,
    'Test::Mojo'      => 0,
    'Test::Exception' => 0.32,
  },
  META_MERGE => {
    requires  => {
      perl => '5.010001'
    },
    resources => {
      license    => 'http://dev.perl.org/licenses/',
      homepage   => 'https://metacpan.org/module/Mojolicious::Plugin::OAuth2::Server',
      bugtracker => 'https://github.com/Humanstate/mojolicious-plugin-oauth2-server/issues',
      repository => 'https://github.com/Humanstate/mojolicious-plugin-oauth2-server'
    },
  },
  test => {
    TESTS => 't/*.t',
  },
);

# vim: ts=4:sw=4:et
