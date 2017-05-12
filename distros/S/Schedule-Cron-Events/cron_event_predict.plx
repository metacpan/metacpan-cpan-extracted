#!/usr/local/bin/perl -w
use strict;
use lib './lib';
use Schedule::Cron::Events;
use Getopt::Std;
use Time::Local;
use vars qw($opt_f $opt_h $opt_p);
getopts('p:f:h');

if ($opt_h) { usage(); }
my $filename = shift || usage();

my $future = 2;
if (defined $opt_f) { $future = $opt_f; }
my $past = 0;
if (defined $opt_p) { $past = $opt_p; }

open (IN, '<$filename') || die "Unable to open '$filename' for read: $!";
while(<IN>) {
	my $obj = new Schedule::Cron::Events($_) || next;
	chomp;
	print "# Original line: $_\n";

	if ($future) {
		for (1..$future) {
				my $date = localtime( timelocal($obj->nextEvent) );
				print "$date - predicted future event\n";
		}
	}
	$obj->resetCounter;
	if ($past) {
		for (1..$past) {
				my $date = localtime( timelocal($obj->previousEvent) );
				print "$date - predicted past event\n";
		}
	}
	print "\n";
}
close IN;


sub usage {
	print qq{
SYNOPSIS

$0 [ -h ] [ -f number ] [ -p number ] <crontab-filename>

Reads the crontab specified and iterates over every line in it, predicting when 
each cron event in the crontab will run. Defaults to predicting the next 2 events.

	-h - show this help
	-f - how many events predited in the future. Default is 2
	-p - how many events predicted for the past. Default is 0.

EXAMPLE

$0 -f 2 -p 2 ~/my.crontab

\$Revision\$

};
	exit;
}

=pod

=head1 NAME

cron_event_predict - Reads a crontab file and predicts when event will/would have run

=head1 SYNOPSIS

cron_event_predict.plx [ -h ] [ -f number ] [ -p number ] <crontab-filename>

=head1 DESCRIPTION

A simple utility program mainly written to provide a worked example of how to use the module,
but also of some use in understanding complex or unfamiliar crontab files.

Reads the crontab specified and iterates over every line in it, predicting when 
each cron event in the crontab will run. Defaults to predicting the next 2 events.

These are the command line arguments:

	-h - show this help
	-f - how many events predited in the future. Default is 2
	-p - how many events predicted for the past. Default is 0.

Here's an example, showing the default of the next 2 predicted occurences of the each cron job:

	dev~/src/cronevent > ./cron_event_predict.plx ~/bin/crontab
	# Original line: 1-56/5 * * * * /usr/local/mrtg-2/bin/mrtg /home/admin/mrtg/mrtg.cfg
	Thu Sep 26 00:41:00 2002 - predicted future event
	Thu Sep 26 00:46:00 2002 - predicted future event
	
	# Original line: 34 */2 * * * /home/analog/analogwrap.bash > /dev/null
	Thu Sep 26 02:34:00 2002 - predicted future event
	Thu Sep 26 04:34:00 2002 - predicted future event
	
	# Original line: 38 18 * * * /home/admin/bin/allpodscript.bash > /dev/null
	Thu Sep 26 18:38:00 2002 - predicted future event
	Fri Sep 27 18:38:00 2002 - predicted future event

And here's an example showing past events too:

	dev~/src/cronevent > ./cron_event_predict.plx -f 1 -p 3 ~/bin/crontab
	# Original line: 1-56/5 * * * * /usr/local/mrtg-2/bin/mrtg /home/admin/mrtg/mrtg.cfg
	Thu Sep 26 00:41:00 2002 - predicted future event
	Thu Sep 26 00:36:00 2002 - predicted past event
	Thu Sep 26 00:31:00 2002 - predicted past event
	Thu Sep 26 00:26:00 2002 - predicted past event
	
	# Original line: 34 */2 * * * /home/analog/analogwrap.bash > /dev/null
	Thu Sep 26 02:34:00 2002 - predicted future event
	Thu Sep 26 00:34:00 2002 - predicted past event
	Wed Sep 25 22:34:00 2002 - predicted past event
	Wed Sep 25 20:34:00 2002 - predicted past event
	
	# Original line: 38 18 * * * /home/admin/bin/allpodscript.bash > /dev/null
	Thu Sep 26 18:38:00 2002 - predicted future event
	Wed Sep 25 18:38:00 2002 - predicted past event
	Tue Sep 24 18:38:00 2002 - predicted past event
	Mon Sep 23 18:38:00 2002 - predicted past event

=cut