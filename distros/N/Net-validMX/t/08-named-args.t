#!/usr/bin/perl -T

use lib 'lib';

use strict;
use warnings;

use Test::More;
plan tests => 22;

use Net::DNS;
use Net::validMX;

# Offline resolver: answers from a fixed zone and counts the lookups
package FakeResolver;

my %zone = (
  'good.example MX'     => ['good.example. 60 IN MX 10 mx.good.example.'],
  'mx.good.example A'   => ['mx.good.example. 60 IN A 93.184.215.14'],
  'implicit.example A'  => ['implicit.example. 60 IN A 93.184.215.14'],
  'private.example A'   => ['private.example. 60 IN A 10.0.0.1'],
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

# get_output_result
is(Net::validMX::get_output_result(email => 'a@b.example', rv => 1, reason => 'Passed'),
   Net::validMX::get_output_result('a@b.example', 1, 'Passed'),
   'get_output_result: named and positional forms match');
is(Net::validMX::get_output_result(reason => 'Bad', email => 'a@b.example', rv => 0),
   "a\@b.example\n\tValid MX? False - Bad\n\n", 'get_output_result: named arguments in any order');
{
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, @_ };
  is(Net::validMX::get_output_result(email => 'a@b.example', rv => 1),
     "a\@b.example\n\tValid MX? True\n\n", 'get_output_result: no reason');
  is(scalar(@warnings), 0, 'get_output_result: no warnings without a reason');
}

# check_email_validity
is(Net::validMX::check_email_validity(email => 'kevin.mcgrail@peregrinehw.com'), 1, 'check_email_validity: named valid');
is(Net::validMX::check_email_validity(email => 'kevin.mcgrail@aol'), 0, 'check_email_validity: named invalid');
is(Net::validMX::check_email_validity('email'), 0, 'check_email_validity: a single argument is positional');

# get_domain_from_email
is(scalar(Net::validMX::get_domain_from_email(email => 'user@dom.example')), 'dom.example', 'get_domain_from_email: named, scalar context');
is_deeply([Net::validMX::get_domain_from_email(email => 'user@dom.example')], ['user', 'dom.example'], 'get_domain_from_email: named, list context');
is(scalar(Net::validMX::get_domain_from_email('user@dom.example')), 'dom.example', 'get_domain_from_email: positional');

# invalid_mx
is_deeply([Net::validMX::invalid_mx(ip => '10.0.0.1')], [Net::validMX::invalid_mx('10.0.0.1')], 'invalid_mx: named and positional forms match');
is((Net::validMX::invalid_mx(ip => '93.184.215.14'))[0], 0, 'invalid_mx: named, public address');

# int_to_truefalse
is(Net::validMX::int_to_truefalse(rv => 1), 'True', 'int_to_truefalse: named true');
is(Net::validMX::int_to_truefalse(rv => 0), 'False', 'int_to_truefalse: named false');
is(Net::validMX::int_to_truefalse(1), 'True', 'int_to_truefalse: positional');

# set_debug
Net::validMX::set_debug(debug => 0);
is(Net::validMX::get_debug(), 0, 'set_debug: named');

# check_email_and_mx forwards the resolver
my $res = FakeResolver->new;
my ($rv, $reason, $email) = Net::validMX::check_email_and_mx(email => 'user @good.example', resolver => $res);
is($rv, 1, 'check_email_and_mx: named, valid');
is($email, 'user@good.example', 'check_email_and_mx: named, sanitized email');
ok($res->{calls} > 0, 'check_email_and_mx: the resolver is forwarded to check_valid_mx');

# check_implicit_mx
$res = FakeResolver->new;
is_deeply([Net::validMX::check_implicit_mx(domain => 'implicit.example', resolver => $res)],
          [Net::validMX::check_implicit_mx('implicit.example', $res, 0, 1)],
          'check_implicit_mx: named and positional forms match');
($rv) = Net::validMX::check_implicit_mx(domain => 'private.example', resolver => $res);
is($rv, 0, 'check_implicit_mx: named, private address fails');
{
  local $Net::validMX::RESOLVER = FakeResolver->new;
  ($rv) = Net::validMX::check_implicit_mx(domain => 'implicit.example');
  is($rv, 1, 'check_implicit_mx: named, default to $Net::validMX::RESOLVER');
}
