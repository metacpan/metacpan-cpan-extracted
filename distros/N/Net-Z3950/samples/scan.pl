#!/usr/bin/perl -w

# $Id: scan.pl,v 1.5 2004/05/07 16:58:15 mike Exp $
#
# e.g. run as follows:
#	cd /usr/local/src/z39.50/NetZ3950
#	PERL_DL_NONLAZY=1 /usr/bin/perl "-Iblib/lib" "-Iblib/arch" \
#		samples/scan.pl bagel 210 gils x responsePosition 5
# OR gondolin.hist.liv.ac.uk 210 l5r foo stepSize 4

use Net::Z3950;
use strict;

my $verbose = 0;
if (@ARGV > 0 && $ARGV[0] eq "-v") {
    $verbose = 1;
    shift;
}

die "Usage: scan.pl <host> <port> <db> <scan-query> [<option> <value>] ...\n"
    unless @ARGV >= 4;
my $host = shift();
my $port = shift();
my $db = shift();
my $scanQuery = shift();
my $mgr = new Net::Z3950::Manager();
while (@ARGV) {
    my $type = shift();
    my $val = shift();
    $mgr->option($type, $val);
}

my $conn = new Net::Z3950::Connection($mgr, $host, $port, databaseName => $db)
    or die "can't connect: ". ($! == -1 ? "init refused" : $!);

my $ss = $conn->scan($scanQuery);
die "scan: " . error($conn) if !defined $ss;

$conn->close();
if ($verbose) {
    use Data::Dumper;
    print Dumper($ss);
}

my $status = $ss->status();
if ($status != Net::Z3950::ScanStatus::Success) {
    print "Scan-status is $status: ";
    if ($status == Net::Z3950::ScanStatus::Failure) {
	my $addinfo = $ss->addinfo();
	print "scan failed\n";
	print "error ", $ss->errcode(), ": ", $ss->errmsg();
	print " ($addinfo)" if $addinfo;
	print "\n";
	exit;
    }
    print "only partial results included\n";
}

my $n = $ss->size();
my $step = $ss->stepSize();
my $pos = $ss->position();

print "Scanned $n entries";
print ", step-size $step" if defined $step;
print ", position=$pos" if defined $pos;
print "\n";

for (my $i = 1; $i <= $n; $i++) {
    my($term, $count) = $ss->term($i-1);
    print  "-->" if defined $pos && $i == $pos;
    if (!defined $term) {
	print "\tNSD: ", $ss->errmsg(), "\n";
    } else {
	print "\t$term ($count)\n";
    }
}


sub error {
    my($x) = @_;

    my $res = "error " . $x->errcode() . ": " . $x->errmsg();
    my $addinfo = $x->addinfo();
    $res .= " ($addinfo)" if defined $addinfo;

    return $res;
}
