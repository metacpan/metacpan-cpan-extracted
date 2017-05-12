#! /usr/bin/perl
#
# tests Params::Validate::Checks::Net hostname check does what's required

use warnings;
use strict;

use Test::More tests => 5;
use Test::Exception;


BEGIN
{
  use_ok 'Params::Validate::Checks', qw<validate as>
      or die "Loading Params::Validate::Checks failed";
  use_ok 'Params::Validate::Checks::Net'
      or die "Loading Params::Validate::Checks failed";
};

sub ping
{
  my %arg = validate @_, {server => {as 'hostname'}};

  $arg{server};
}

lives_and { is ping(server => 'www.thedailywtf.com'), 'www.thedailywtf.com' }
    'allows valid domain name';

lives_and { is ping(server => 'nagios'), 'nagios' }
    'allows unqualified hostname';

throws_ok { ping(server => 'and/or') }
    qr/did not pass the 'hostname' callback/,
    'complains at invalid characters for a hostname';
