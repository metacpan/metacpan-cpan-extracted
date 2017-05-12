#!/usr/bin/perl
# cellsynt-sms: Send SMS from the command line
# Simple example script for Net::SMS::Cellsynt
#
# This example uses hard coded authentication information.
#
# Copyright 2010, Olof Johansson <zibri@cpan.org>
#
# This program is free software; you can redistribute it and/or 
# modify it under the same terms as Perl itself. 

use strict;
use warnings;
use Net::SMS::Cellsynt;
use Encode::Detect::Detector;
use Text::Iconv;

if($#ARGV != 1) {
	print STDERR "Usage: ./example.pl <number> <message>\n\n";
	print STDERR "Number is of the format \n\t";
	print STDERR "00 <country code> <national number w/o leading zero>\n\n";
	print STDERR "Example: 0700123456 (swedish number) -> 0046700123456\n";
	exit(1);
}

my $sms = Net::SMS::Cellsynt->new(
	username=>'zibri',
	password=>'s3kr3t',
	origtype=>'alpha',
	orig=>'zibri',
	#test=>1,
);

my $text = $ARGV[1];
my $charset = detect($text);

if($charset ne 'ISO-8859-1') {
	my $conv = Text::Iconv->new($charset, 'ISO-8859-1');
	$text = $conv->convert($text);
}

my $ret = $sms->send_sms(
	to=>$ARGV[0],
	text=>$text,
);

if($ret->{status} =~ /^error/) {
	print STDERR "$ret->{status}: $ret->{message}\n";
} elsif($ret->{status} eq 'ok-test') {
	print STDERR "$ret->{uri}\n";
} else {
	print STDERR "ok: $ret->{id}\n";
}

