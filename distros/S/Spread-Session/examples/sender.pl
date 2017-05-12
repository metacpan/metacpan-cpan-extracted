#!/usr/bin/perl
#
# Simple example of a Spread publisher.  Sends one message and terminates.
#

use strict;
use Spread;
use Spread::Session;

use Log::Channel;
enable Log::Channel "Spread::Session";
enable Log::Channel "Spread::Session::message";

my $queue_name = shift @ARGV || die;
my $message = shift @ARGV || die;

my $session = new Spread::Session(
				  MESSAGE_CALLBACK => \&callback,
		    );
$session->publish($queue_name, $message);


sub callback {
    my ($msg) = @_;

    print "SENDER: $msg->{SENDER}\n";
    print "GROUPS: [", join(",", @{$msg->{GROUPS}}), "]\n";
    print "MESSAGE:\n", $msg->{BODY}, "\n";
}
