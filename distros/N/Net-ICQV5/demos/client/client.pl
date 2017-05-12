#!/usr/bin/perl
# Copyright  (c) 2001
# http://www.tapor.com/NetICQ/

use Getopt::Std;
use Term::ReadLine;
use Net::ICQV5;

require 'SNlib.pl';

my $DEBUG = 1;

my %opt;
my $readingpid;
my $mainpid;
my $keeppid;
$uinsfile = "uins.txt";

getopts('v', \%opt);

if ($opt{"v"}) 
    {
    print "Basic Net::ICQV5 client built with:\n" . Net::ICQV5::version() . "\n";
    exit;
    }

#$ICQ = new Net::ICQV5 ('192.168.78.5','5001');
#$ICQ = new Net::ICQV5 ('192.168.78.5','4000');
$ICQ = new Net::ICQV5 ('samp','8040');
#$ICQ = new Net::ICQV5 ('icq4.mirabilis.com','4000');

if (!$ICQ) 
    {
    &HTMLdie("Failed to connect to ICQ server.\n$@\n");
    }

$ICQ->turnoutput(1);
$ICQ->turnlog(1);

$uinpassword = &SelectRandomStringFromFile($uinsfile);

@pairs = split(/:/,$uinpassword);
$uin = $pairs[0];
$password = $pairs[1];

$ICQ->login($uin,$password) || die "Couldn't log on.";

$mainpid = $$;

$SIG{INT} = 'IGNORE';
&start_reading_thread();
&start_keep_thread();

my $Input = new Term::ReadLine 'Net::ICQ Client';
while (defined($_ = $Input->readline("[command]> "))) 
	{
        next if /^\s*$/;

        if (/^ml\s+(.+)$/i) 
	    {
            # msg in $1;
            $ICQ->send_msg('last', $1);

            } elsif (/^ul\s+(.+?)\s+(.+)/i) {
            # msg in $1;
            $ICQ->send_url('last', $1, $2);

            } elsif (/^mirroron/i) {
            $ICQ->select_mirror_mode(1);
	    &restart_reading_thread();

            } elsif (/^mirroroff/i) {
            $ICQ->select_mirror_mode(0);
	    &restart_reading_thread();

            } elsif (/^m\s+(.*?)\s+(.*)/i) {
            # msg to $1, text = $2;
            $ICQ->send_msg($1, $2);

            } elsif (/^u\s+(.*?)\s+(.*)\s+(.*)/i) {
            # msg to $1, url = $2, desc = $3;
            $ICQ->send_url($1, $2, $3);

            } elsif (/^search (.+)$/i) {
            # search for a user, $1 is UIN, email or name
            $ICQ->search($1);

            } elsif (/^(quit|exit|q)$/i) {
            # exit program
            last;

            } elsif (/^cs\s+(.+)$/i) {
      
            my $status = uc('STATUS_' . $1);
            $ICQ->change_status($status) or print "\nStatus '$1' is invalid\n";
	 
            }  elsif (/^help$/i) {
            # display helptext
    	    print "\n";
            print "Commands:\n";
            print "quit - exit program\n";
            print "cs STATUS - change status (ONLINE, AWAY, DND, OCCUPIED, FFC, INVISIBLE)\n";
            print "m UIN MESSAGE - send message to UIN\n";
            print "ml MESSAGE - send message to last UIN\n";
            print "u UIN URL DESC - send url to UIN\n";
            print "ul URL DESC - send url to last UIN\n";
            print "mirroron - turn on mirror mode\n";
            print "mirroroff - turn off mirror mode\n";
            print "\n";

            } else {
    	    print "Unknown command: $_\n";
            print "Use 'help' for help\n";
            }
        }
kill 'TERM' => $readingpid;
kill 'TERM' => $keeppid;
$ICQ->logout();
exit;    

##############################################################################
sub start_reading_thread()
{
if($readingpid = fork)
    {
    return;
    }
else
    {
    while ($ICQ->incoming_packet_waiting()) 
	{
        $ICQ->incoming_process_packet();
        }
    }
}
##############################################################################
sub start_keep_thread() {
if($keeppid = fork)
    {
    return;
    }
else
    {
    while (1) 
	{
	sleep(120);
        $ICQ->send_keepalive();
        }
    }
}
##############################################################################
sub restart_reading_thread()
{
kill 'TERM' => $readingpid;
&start_reading_thread();
}
##############################################################################
