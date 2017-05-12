#!perl -T

# Aims to test basic usage of Net::DNS::CloudFlare::DDNS
use Modern::Perl '2012';
use autodie      ':all';
no  indirect     'fatal';

use Readonly;
use Test::More;
use Test::Exception;
use Try::Tiny;

use Net::DNS::CloudFlare::DDNS;

plan tests => 2;
Readonly my $USER  => 'blah';
Readonly my $KEY   => 'blah';
Readonly my $ZONES => [{ zone => 'zone1',
                         domains => [ 'dom1', 'dom2' ],},
                       { zone => 'zone2',
                         domains => [ 'dom3', 'dom4'],},];
# Construction
Readonly my $CLASS => 'Net::DNS::CloudFlare::DDNS';
lives_ok { $CLASS->new( user => $USER, apikey  => $KEY, zones => $ZONES)}
           "construction with valid credentials works";
Readonly my $ddns => try { Net::DNS::CloudFlare::DDNS::->new(
  user   => $USER,
  apikey => $KEY,
  zones  => $ZONES,)};

# This should fail in any number of ways but continue despite emitting warnings
lives_ok { $ddns->update; };
