#!/usr/bin/perl -w

# $Id: test.pl,v 1.1.1.1 2005/04/19 15:29:17 dk Exp $
my $loaded;
BEGIN { $| = 1; print "1..3\n"; }
END {print "not ok 1\n" unless $loaded;}
use Regexp::Log::DateRange;
use strict;
$loaded = 1;
print "ok 1\n";


my @months = qw(. jan feb mar apr may jun jul aug sep oct nov dec);
my @dates;
for ( 1..10000) {
	my @date = ( int(rand(12)) + 1, int(rand(31) + 1), 
		int(rand(24)), int(rand(60)));
	push @dates, [ 
		sprintf("%s %d %02d:%02d:00", $months[$date[0]], @date[1..3]),
		$date[3] + $date[2]*60 + $date[1]*24*60 + $date[0]*24*60*31
	];
}

my $ok = 'ok';
for ( 1 .. 100) {
	my @date = ( int(rand(12)) + 1, int(rand(31) + 1), 
		int(rand(24)), int(rand(60)));
	my $date = $date[3] + $date[2]*60 + $date[1]*24*60 + $date[0]*24*60*31;
	my $dline = sprintf "%s/%d/%02d:%02d", $months[$date[0]], @date[1..3];
	my $jan1 = [ 1, 1, 0, 0];
	my $rx = Regexp::Log::DateRange-> new('syslog', $jan1, \@date);
	for ( @dates) {
		my ( $line, $num) = @$_;
		my $ret = ( $line =~ /$rx/) ? 1 : 0;
		my $expected = ( $num <= $date) ? 1 : 0;
		next if $ret == $expected;
		warn "failed: $line <~ 'to $dline' matched '$ret', expected '$expected'\n";
		$ok = 'not ok';
		last;
	}
}
print "$ok 2\n";


$ok = 'ok';
for ( 1 .. 100) {
	my @date = ( int(rand(12)) + 1, int(rand(31) + 1), 
		int(rand(24)), int(rand(60)));
	my $date = $date[3] + $date[2]*60 + $date[1]*24*60 + $date[0]*24*60*31;
	my $dline = sprintf "%s/%d/%02d:%02d", $months[$date[0]], @date[1..3];
	my $dec31 = [ 12, 31, 23, 59];
	my $rx = Regexp::Log::DateRange-> new('syslog', \@date, $dec31);
	for ( @dates) {
		my ( $line, $num) = @$_;
		my $ret = ( $line =~ /$rx/) ? 1 : 0;
		my $expected = ( $num >= $date) ? 1 : 0;
		next if $ret == $expected;
		warn "failed: $line >~ 'from $dline' matched '$ret', expected '$expected'\n";
		$ok = 'not ok';
		last;
	}
}
print "$ok 3\n";
