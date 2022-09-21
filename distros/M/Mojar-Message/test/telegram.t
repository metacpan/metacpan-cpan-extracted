use Mojo::Base -strict;
use Test::More;

# Disable IPv6 and libev
BEGIN {
  $ENV{MOJO_MODE}    = 'testing';
  $ENV{MOJO_NO_IPV6} = 1;
  $ENV{MOJO_REACTOR} = 'Mojo::Reactor::Poll';
}

use Mojar::Config;
use Mojar::Message::Telegram;
use Mojo::Promise;

plan skip_all => 'set TEST_TELEGRAM to enable this test (developer only!)'
  unless my $filename = $ENV{TEST_TELEGRAM};

die 'Expects a .conf configuration file' unless $filename =~ /\.conf$/;
my $config = Mojar::Config->load($filename);
my $recipient = $config->{telegram}{friends}[0]{id};
my $msg;

subtest q{Synchronous} => sub {
  ok $msg = Mojar::Message::Telegram->new(
    token => $config->{telegram}{token}
  ), 'construct Telegram agent';
  ok $msg->send(
    message   => 'First test message',
    quiet     => 1,
    recipient => $recipient,
  ), 'send first message (sync)';
  ok $msg->send(
    message   => "Second message: \N{U+26A0} \N{U+2714} \N{U+2620}",
    quiet     => 1,
    recipient => $recipient,
  )->send(
    message   => "Third message: \N{U+1F4A9}",
    quiet     => 1,
    recipient => $recipient,
  ), 'send more messages (sync)';
};

subtest q{Asynchronous} => sub {
  my @results;
  my $promise0 = Mojo::Promise->new;
  my $promise1 = Mojo::Promise->new;

  ok $msg->send(
    message   => 'First asynchronous message',
    quiet     => 1,
    recipient => $recipient,
    sub { $_[1] ? $promise0->reject($_[1]{message}) : $promise0->resolve(1) }
  )->send(
    message   => 'Second asynchronous message',
    quiet     => 1,
    recipient => $recipient,
    sub { $_[1] ? $promise1->reject($_[1]{message}) : $promise1->resolve(1) }
  ), 'send messages async';
  Mojo::Promise->all($promise0, $promise1)->then(sub {
    @results = @_;
  })->catch(sub {
    my ($err) = @_;
    fail "Could not send message: $err";
  })->wait;

  ok $results[0], 'First callback';
  ok $results[1], 'Second callback';
};

done_testing;
