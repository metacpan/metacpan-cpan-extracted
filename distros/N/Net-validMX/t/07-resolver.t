#!/usr/bin/perl -T

use lib 'lib';

use strict;
use warnings;

use Test::More;
plan tests => 9;

use Net::DNS;
use Net::validMX;

# Offline resolver: answers from a fixed zone and counts the lookups
package FakeResolver;

my %zone = (
  'good.example MX'    => ['good.example. 60 IN MX 10 mx.good.example.'],
  'mx.good.example A'  => ['mx.good.example. 60 IN A 93.184.215.14'],
  'blank.example MX'   => ['blank.example. 60 IN MX 0 .'],
);

sub new { return bless { calls => 0 }, shift; }

sub send {
  my ($self, $name, $type) = @_;
  $self->{calls}++;
  $name =~ s/\.$//;
  my $rrs = $zone{"$name $type"} // [];
  my $pkt = Net::DNS::Packet->new($name, $type);
  $pkt->header->qr(1);
  $pkt->header->rcode(@$rrs ? 'NOERROR' : 'NXDOMAIN');
  $pkt->push(answer => Net::DNS::RR->new($_)) foreach @$rrs;
  return $pkt;
}

sub errorstring { return 'NOERROR'; }

package main;

# per call parameter
my $res = FakeResolver->new;
my ($rv, $reason) = Net::validMX::check_valid_mx(email => 'user@good.example', resolver => $res);
is($rv, 1, 'valid MX through the resolver parameter');
ok($res->{calls} > 0, 'the resolver parameter is used');

($rv, $reason) = Net::validMX::check_valid_mx(email => 'user@blank.example', resolver => $res);
is($rv, 0, 'blank MX fails through the resolver parameter');
like($reason, qr/blank MX record at Priority 0/, 'null MX reason');

# package global
my $global = FakeResolver->new;
{
  local $Net::validMX::RESOLVER = $global;
  ($rv) = Net::validMX::check_valid_mx('user@good.example');
  is($rv, 1, 'valid MX through $Net::validMX::RESOLVER');
  ok($global->{calls} > 0, '$Net::validMX::RESOLVER is used');
}

# OO interface
my $oo = FakeResolver->new;
my $validmx = Net::validMX->new(resolver => $oo);
($rv) = $validmx->check_valid_mx(email => 'user@good.example');
is($rv, 1, 'valid MX through the OO resolver');
ok($oo->{calls} > 0, 'the resolver passed to new is used');

# the per call parameter wins over the object one
my $call = FakeResolver->new;
my $before = $oo->{calls};
$validmx->check_valid_mx(email => 'user@good.example', resolver => $call);
is($oo->{calls}, $before, 'the resolver parameter overrides the OO resolver');
