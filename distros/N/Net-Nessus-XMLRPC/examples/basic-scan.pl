#!/usr/bin/perl

use strict;
use Net::Nessus::XMLRPC;

# '' is same as https://localhost:8834/
my $n = Net::Nessus::XMLRPC->new ('','user','pass');

die "URL, user or passwd not correct: ".$n->nurl."\n" unless ($n->logged_in);

print "Logged in\n";
my $polid=$n->policy_get_first;
print "Using policy ID: $polid ";
my $polname=$n->policy_get_name($polid);
print "with name: $polname\n";
my $scanname="perl-test";
my $targets="127.0.0.1";
my $scanid=$n->scan_new($polid,$scanname,$targets);

$SIG{INT} = \&ctrlc;
while (not $n->scan_finished($scanid)) {
	print "$scanid: ".$n->scan_status($scanid)."\n";	
	sleep 15;
}
$SIG{'INT'} = 'DEFAULT';

print "$scanid: ".$n->scan_status($scanid)."\n";	
my $reportcont=$n->report_file_download($scanid);
my $reportfile="report.xml";
open (FILE,">$reportfile") or die "Cannot open report file $reportfile: $!";
print FILE $reportcont;
close (FILE);

sub ctrlc {
    $SIG{INT} = \&ctrlc;
    print "\nCTRL+C presssed, stopping scan.\n";
    $n->scan_stop($scanid);
}
