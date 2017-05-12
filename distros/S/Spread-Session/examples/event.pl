#!/usr/bin/perl
#
# Using Spread::Session with Event
#

use strict;
use Spread::Session;
use Event qw(loop unloop);

use Log::Channel;
enable Log::Channel "Spread::Session";

my $group = shift @ARGV || "example";

my $session = new Spread::Session(
		     MESSAGE_CALLBACK => sub {
			 my ($msg) = @_;

			 print "THE SENDER IS $msg->{SENDER}\n";
			 print "GROUPS: [", join(",", @{$msg->{GROUPS}}), "]\n";
			 print "MESSAGE:\n", $msg->{BODY}, "\n\n";

			 $msg->{SESSION}->publish($msg->{SENDER},
						  "the response!");
		     },
		    );
$session->subscribe($group);

Event->io(fd => $session->{MAILBOX},
	  cb => sub { $session->receive(0) },
	 );
Event->timer(interval => 5,
	     cb => sub { print STDERR "(5 second timer)\n" },
	    );
Event::loop;

