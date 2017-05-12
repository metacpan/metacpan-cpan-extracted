#!/usr/bin/perl

# It's Perl alternative of binary sercmd provided with SER

use warnings;
use strict;

use Socket;
use Ser::BinRPC;

my $version = '0.1';
my $script_name = $0;
$script_name =~ s!^.*/!!;

sub printUsage {
	print "$script_name, Version: $version\n";
	print "usage: $script_name [-v] [-h] [-s conn_string] command [params [params ...]]\n";
	print "Example:\n";
	print "  $script_name core.uptime\n";
	print "  $script_name -s udp:localhost:2049 core.ps\n";
}

my $arg;
my $cmd = "";
my @cmd_params = ();

my $conn = Ser::BinRPC->new();

while ($#ARGV >= 0) {
	$arg = shift(@ARGV);
	if ($arg eq '-v') {
		$conn->{verbose}++;
	} elsif ($arg eq '-s') {
		unless ($conn->parse_connection_string(shift @ARGV)) {
			die "$conn->{errs}\n";
		}
	} elsif ($arg eq '-h') {
		&printUsage();
		exit(0);
	} elsif ( $arg !~ /^-/) {
		if (!$cmd) {
			$cmd = $arg;
		} else {
			push(@cmd_params, $arg);
		}
	}
}

unless ($conn->open()) {
	die "$conn->{errs}\n";
}

my @result;
my $ret = $conn->command($cmd, \@cmd_params, \@result);
if ($ret < 0) {
	die sprintf("%d - %s\n", $result[0], $result[1]);
} elsif ($ret > 0) {
	$conn->print_result(\*STDOUT, \@result);
} else {
	die "$conn->{errs}\n";
}
exit(0);

