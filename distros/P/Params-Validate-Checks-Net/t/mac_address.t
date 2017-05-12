#! /usr/bin/perl
#
# tests Params::Validate::Checks::Net mac_address check does what's required

use warnings;
use strict;

use Test::More tests => 6;
use Test::Exception;


BEGIN
{
  use_ok 'Params::Validate::Checks', qw<validate as>
      or die "Loading Params::Validate::Checks failed";
  use_ok 'Params::Validate::Checks::Net'
      or die "Loading Params::Validate::Checks failed";
};


sub enable
{
  my %arg = validate @_, {nic => {as 'mac_address'}};

  $arg{nic};
}

lives_and { is enable(nic => '00:11:43:CC:A5:56'), '00:11:43:CC:A5:56' }
    'allows valid mac address';

throws_ok { enable(nic => '01:23:45:67:89:AZ') }
    qr/did not pass regex check/,
    'complains at invalid character';

throws_ok { enable(nic => '11:22:33:44:55') }
    qr/did not pass regex check/,
    'complains at too-short mac address';

throws_ok { enable(nic => '11:22:33:44:55:66:77') }
    qr/did not pass regex check/,
    'complains at too-long address';
