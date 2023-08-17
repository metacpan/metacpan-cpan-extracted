#!/usr/local/bin/perl -w

use strict;

use SNMP_Session;
use BER;
use Time::HiRes qw(gettimeofday tv_interval);

sub usage();

$SNMP_Session::suppress_warnings = 1;

my ($host, $community, $interval, $port, $factor, @OIDS);

$interval = 5;
$port = 161;
$factor = 1;

while ($#ARGV >= 0) {
    $_ = shift @ARGV;
    if (/^-t$/) {
	$interval = shift @ARGV;
    } elsif (/^-p$/) {
	$port = shift @ARGV;
    } elsif (/^-b$/) {
	$factor = 8;
    } elsif (! defined ($host)) {
	$host = $_;
    } elsif (! defined ($community)) {
	$community = $_;
    } else {
	push @OIDS, $_;
    }
}
usage() if !defined $host || !defined $community || !@OIDS;

my @encoded_oids = @OIDS;

grep (($_ = encode_oid (split ('\.',$_)) || die "cannot encode $_"),
      @encoded_oids);

my $session = SNMP_Session->open ($host, $community, $port)
    || die "couldn't open SNMP session to $host";

my %last_values;
my $last_time;

get_initial_values ($session, @encoded_oids)
    || die "Couldn't get initial values";
while (1) {
    sleep $interval;
    print_value_changes ($session, @encoded_oids);
}
$session->close ();
1;

sub usage() {
    die "Usage: $0 [-t interval] [-p port] host community OID...";
}

sub get_initial_values ($@) {
    my ($session, @encoded_oids) = @_;

    if (!$session->get_request_response (@encoded_oids)) {
	print STDERR "Request to $host failed: $SNMP_Session::errmsg\n";
    } else {
	my $response = $session->pdu_buffer;
	my ($bindings) = $session->decode_get_response ($response);

	$last_time = [gettimeofday()];
	while ($bindings ne '') {
	    my $binding;
	    ($binding,$bindings) = decode_sequence ($bindings);
	    my ($oid,$value) = decode_by_template ($binding, "%O%@");
	    grep ($_=pretty_print $_, $oid, $value);
	    $last_values{$oid} = $value;
	}
    }
    1;
}

sub print_value_changes ($@) {
    my ($session, @encoded_oids) = @_;
    if (!$session->get_request_response (@encoded_oids)) {
	print STDERR "Request to $host failed: $SNMP_Session::errmsg\n";
    } else {
	my $this_time = [gettimeofday()];
	my $response = $session->pdu_buffer;
	my ($bindings) = $session->decode_get_response ($response);
	my $real_interval = tv_interval ($last_time, $this_time);
	$last_time = $this_time;

	while ($bindings ne '') {
	    my $binding;
	    ($binding,$bindings) = decode_sequence ($bindings);
	    my ($oid,$value) = decode_by_template ($binding, "%O%@");
	    grep ($_=pretty_print $_, $oid, $value);
	    my $diff = $value - $last_values{$oid};
	    printf "%12.2f",$diff/$real_interval*$factor,"\n";
	    $last_values{$oid} = $value;
	}
	print "\n";
    }
    1;
}
