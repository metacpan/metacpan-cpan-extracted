#!/usr/bin/perl
#
# Using Spread::Session with POE alone
#

use warnings;
use strict;

use Spread::Session;
use POE;

use Log::Channel;
enable Log::Channel "Spread::Session";

my $group = shift @ARGV || 'test';

POE::Session->create
  ( inline_states =>
    { _start => sub {
        my ($kernel, $heap) = @_[KERNEL, HEAP];

        $heap->{spread} = Spread::Session->new(
					       MESSAGE_CALLBACK =>
	sub {
              my ($msg) = @_;

              print "THE SENDER IS $msg->{SENDER}\n";
              print "GROUPS: [", join(",", @{$msg->{GROUPS}}), "]\n";
              print "MESSAGE:\n", $msg->{BODY}, "\n\n";

              $heap->{spread}->publish($msg->{SENDER}, "the response!");
            },
          );
        $heap->{spread}->subscribe($group);

	my $fh;
	open($fh, "<&=$heap->{spread}->{MAILBOX}") or die;

	$kernel->select_read( $fh, "read_spread" );

        # $kernel->delay( "timer_spread" ); to stop the timer.
        $kernel->delay( timer_spread => 5 );
      },

      read_spread => sub {
        my $heap = $_[HEAP];
        $heap->{spread}->receive(0);
      },

      timer_spread => sub {
        print STDERR "(5 second timer)\n";
        $_[KERNEL]->delay( timer_spread => 5 );
      },
    }
  );

$poe_kernel->run();
