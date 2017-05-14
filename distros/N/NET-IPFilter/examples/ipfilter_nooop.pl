#!/usr/bin/perl

use strict;
use Socket qw ( inet_ntoa );
use Time::HiRes;
use Benchmark;

my $start = new Benchmark;
my $IPtoCheck	= ip2long("222.231.45.255"); #"238.99.160.101"

my @ARRAY = ();

open(RH,"<../ipfilter.dat");
	while( my $entry = <RH> ){
	
		chomp($entry);
		$entry =~ s/^\s+//;
		$entry =~ s/\s+$//;

		next if ( $entry =~ /^#/g || $entry =~ /#/g );
		next if ( length($entry) <= 0 );
		my ($IPRange, undef, $DESC) = split(",", $entry);
		next if ( $DESC =~ /\[BG\]FreeSP/ig );	

		my ($IP_Start, $IP_End) = split("-", $IPRange );
		my $IPStart 			= ip2long( $IP_Start );
		my $IPEnd				= ip2long( $IP_End );

		push(@ARRAY, "$IPStart-$IPEnd");

	}; # while( my $entry = <RH> ){

close RH;

my $ArrayCount = @ARRAY;

# end timer
my $end = new Benchmark;
# calculate difference
my $diff = timediff($end, $start);

print "Time taken was ", timestr($diff, 'all'), " seconds\n";

sleep 3;

my $start1 = new Benchmark;
my $c = 0;

foreach my $arr ( @ARRAY) {

	$c++;
	my ($RangFrom, $RangTo) = split("-", $arr);
	
	if ( $IPtoCheck > $RangFrom && $IPtoCheck < $RangTo ) {
		
		# end timer
		my $end1 = new Benchmark;
		# calculate difference
		my $diff = timediff($end1, $start1);
		print "Time taken was ", timestr($diff, 'all'), " seconds\n";
		my $s = long2ip($RangFrom);
		my $e = long2ip($RangTo);
		die "[$c/1.2 MIO] $IPtoCheck must be blocked ($s, $e)\n";
	
	#	return 0;	# to be blocked
		
	};
	if ( $IPtoCheck <=> $RangFrom || $IPtoCheck <=> $RangTo ) {
		
		# end timer
		my $end1 = new Benchmark;
		# calculate difference
		my $diff = timediff($end1, $start1);
		my $s = long2ip($RangFrom);
		my $e = long2ip($RangTo);
		print "Time taken was ", timestr($diff, 'all'), " seconds\n";

		die "[$c/1.2 MIO] $IPtoCheck must be blocked ($s, $e)\n";

	#	return 0;	# to be blocked
			
	}; # if ( $IPtoCheck > $RangTo || $IPtoCheck < $RangFrom ) {

}; # foreach my $arr ( @ARRAY) {



exit;



sub  ip2long(){

	my $ip		= shift; # 4 sec ipfilter.dat 4-quore
	my @numbers	= split(/\./,$ip);
	return ($numbers[0] * 16777216) + ($numbers[1] * 65536) + ($numbers[2] * 256) + ($numbers[3]);

}; # sub  ip2long() {


sub long2ip(){
	my $long = shift;
	return inet_ntoa(pack("N*", $long));
}; # sub long2ip(){

