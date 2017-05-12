# ============
# send.t
# ============
use Mojo::Base -strict;
use Test::More;

# Disable IPv6 and libev
BEGIN {
  $ENV{MOJO_MODE}    = 'testing';
  $ENV{MOJO_NO_IPV6} = 1;
  $ENV{MOJO_REACTOR} = 'Mojo::Reactor::Poll';
}

use Mojar::Config;
use Mojar::Message::BulkSms;
use Mojar::Util 'dumper';

plan skip_all => 'set TEST_ACCESS to enable this test (developer only!)'
  unless $ENV{TEST_ACCESS};

my $config = Mojar::Config->load('data/credentials.conf');
my $sms;

subtest q{Synchronous} => sub {
  ok $sms = Mojar::Message::BulkSms->new(
    username => $config->{username},
    password => $config->{password}
  ), 'Constructed SMS agent';
  ok $sms->send(
    recipient => $config->{recipient},
    message => 'First message'
  )->send(message => 'Second message'), 'Sent sync';
};

subtest q{Asynchronous} => sub {
  my @results;
  my $delay = Mojo::IOLoop->delay;
  my @end = ($delay->begin, $delay->begin);
  ok $sms->send(message => 'First asynchronous message' => sub {
    my ($s, $e) = @_;
    $results[0]++;
    $end[0]->();
  })
      ->send(message => 'Second asynchronous message' => sub {
    $results[1]++;
    $end[1]->();
  }), 'Sent async';
  $delay->wait;
  ok $results[0], 'First callback';
  ok $results[1], 'Second callback';
};

done_testing();
