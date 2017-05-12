#!/usr/bin/perl

# Example rndc script

use strict;
use warnings;

use FindBin qw($Bin);

use lib "$Bin/../blib", "$Bin/../lib";

use Net::RNDC;

my $key = shift;
my $host = shift;
my $cmd = shift;

unless ($cmd) {
	die "Usage: $0 <key> <host> <command>\n";
}

my $rndc = Net::RNDC->new(
	host => $host,
	key  => $key,
);

if ($rndc->do($cmd)) {
	print $rndc->response . "\n";
} else {
	print "Error: " . $rndc->error . "\n";
}

=head1 NAME

rndc.pl - Example rndc script for communicating with BIND.

=head1 SYNOPSIS

Usage:

  ./rndc.pl <key> <host> <command>

IE:

  ./rndc.pl aabc localhost status

=head1 DESCRIPTION

This example script shows usage of L<Net::DNS>. It requires the rndc key for 
communicating with BIND, the hostname of the BIND to communicate with, and the 
command in question.

On success it outputs the response from BIND, otherwise an error prefixed with 
"Error: ".

=head1 AUTHOR

Matthew Horsfall (alh) <WolfSage@gmail.com>

=head1 LICENSE

You may distribute this code under the same terms as Perl itself.

=cut
