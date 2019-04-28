#!perl

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME          => 'Net::OAuth2::AuthorizationServer',
  ABSTRACT_FROM => 'lib/Net/OAuth2/AuthorizationServer.pm',
  VERSION_FROM  => 'lib//Net/OAuth2/AuthorizationServer.pm',
  AUTHOR        => 'Lee Johnson <leejo@cpan.org>',
  LICENSE       => 'perl',
  PREREQ_PM => {
    'Moo'             => '2.000002',
    'Types::Standard' => '1.000005',
    'MIME::Base64'    => 0,
    'Time::HiRes'     => 0,
    'Carp'            => 0,
    'CryptX'          => '0.021',
    'Mojo::JWT'       => '0.04',
    'Try::Tiny'       => '0.22',
    'Crypt::JWT'      => '0.023',
  },
  BUILD_REQUIRES => {
    'Test::Most'      => 0,
    'Test::Exception' => 0.32,
  },
  META_MERGE => {
    requires  => {
      perl => '5.010001'
    },
    resources => {
      license    => 'http://dev.perl.org/licenses/',
      homepage   => 'https://metacpan.org/module/Net::OAuth2::AuthorizationServer',
      bugtracker => 'https://github.com/Humanstate/net-oauth2-authorizationserver/issues',
      repository => 'https://github.com/Humanstate/net-oauth2-authorizationserver'
    },
  },
  test => {
    RECURSIVE_TEST_FILES => 1,
  },
);

# vim: ts=4:sw=4:et
