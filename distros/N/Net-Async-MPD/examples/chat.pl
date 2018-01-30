#!/usr/bin/env perl

use strict;
use warnings;

use PerlX::Maybe;
use Net::Async::MPD;
use IO::Async::Timer::Periodic;

# use Log::Any::Adapter;
# Log::Any::Adapter->set( 'Stderr', log_level => 'trace' );

my %accounts = (
  alice   => Net::Async::MPD->new( maybe host => $ARGV[0], auto_connect => 1 ),
  bob     => Net::Async::MPD->new( maybe host => $ARGV[0], auto_connect => 1 ),
  charlie => Net::Async::MPD->new( maybe host => $ARGV[0], auto_connect => 1 ),
);

# Accounts have a channel of their own that they send messages to
# Other accounts can follow them by subscribing to that channel

# Accounts subscribe to their own channel because sending a message to a
# channel without subscribers is an error.
foreach my $name (keys %accounts) {
  my @commands = map { [ subscribe => $_ ] } keys %accounts;
  $accounts{$name}->send( \@commands )->get;
}

# Check for messages every X seconds
my $interval = 1;

# Check for messages in channels this account is subscribed to
my $timer = IO::Async::Timer::Periodic->new(
  first_interval => 1,
  interval => $interval,
  on_tick => sub {
    # We check for messages for all accounts
    foreach my $name (keys %accounts) {
      $accounts{$name}->send( 'read_messages', sub {

        # The message payload is an array of hashes. Each has the name of the
        # channel (= the sender) and an arrayref with the unseen messages
        foreach my $channel (@{ shift() }) {
          # Print who said who, and reply. We don't want to be rude!
          my ($sender, $messages) = ($channel->{channel}, $channel->{message});

          if ($sender eq $name) {
            print "$name says: $_\n" foreach @{$messages};
            next;
          }

          foreach my $message (@{$messages}) {
            next unless $message =~ /(testing|$name)/i;

            $accounts{$name}->send(
              send_message => $name, qq{"I hear you, $sender!"}
            );
          }
        }
      });
    };
  },
);

my $loop = IO::Async::Loop->new;
my $finished = $loop->new_future;

# Set listeners to finish when/if the connection is closed
$accounts{$_}->on( close => sub { $finished->done unless $finished->is_ready })
  foreach keys %accounts;

$loop->add( $timer );
$timer->start;

# Send the first message
$accounts{alice}->send( send_message => 'alice', '"Testing..."' );

$finished->get;
