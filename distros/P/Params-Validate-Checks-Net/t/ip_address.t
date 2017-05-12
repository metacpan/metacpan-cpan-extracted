#! /usr/bin/perl
#
# tests Params::Validate::Checks::Net ip_address and public_ip_address checks
# do what's required

use warnings;
use strict;

use Test::More tests => 14;
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
  my %arg = validate @_, {server => {as 'ip_address'}};

  $arg{server};
}

lives_and { is ping(server => '212.69.37.168'), '212.69.37.168' }
    'allows public IP address';

lives_and { is ping(server => '10.0.0.2'), '10.0.0.2' }
    'allows private IP address';

throws_ok { ping(server => 'www.stgeorgescrypt.org.uk') }
    qr/did not pass the 'ip_address' callback/,
    'complains at hostname instead of IP address';

throws_ok { ping(server => '100.200.256.1') }
    qr/did not pass the 'ip_address' callback/,
    'complains at IP address with component over 255';

throws_ok { ping(server => '201.202.203') }
    qr/did not pass the 'ip_address' callback/,
    'complains at IP address with only 3 components';

throws_ok { ping(server => '111.112.113.114.115') }
    qr/did not pass the 'ip_address' callback/,
    'complains at IP address with 5 components';


sub log_request
{
  my %arg = validate @_, {source => {as 'public_ip_address'}};

  $arg{source};
}

lives_and { is log_request(source => '212.69.37.168'), '212.69.37.168' }
    'allows public IP address';

throws_ok { log_request(source => '10.0.0.2') }
    qr/did not pass the 'public_ip_address' callback/,
    'complains at private IP address';

throws_ok { log_request(source => 'www.stgeorgescrypt.org.uk') }
    qr/did not pass the 'public_ip_address' callback/,
    'complains at hostname instead of IP address';

throws_ok { log_request(source => '100.200.256.1') }
    qr/did not pass the 'public_ip_address' callback/,
    'complains at IP address with component over 255';

throws_ok { log_request(source => '201.202.203') }
    qr/did not pass the 'public_ip_address' callback/,
    'complains at IP address with only 3 components';

throws_ok { log_request(source => '111.112.113.114.115') }
    qr/did not pass the 'public_ip_address' callback/,
    'complains at IP address with 5 components';
