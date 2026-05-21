#!/usr/bin/env perl

use 5.042.2;
no source::encoding;
use warnings FATAL => 'all';
use autodie ':all';
use Stats::LikeR; # mean
use Time::HiRes;
use List::Util 'sum';
use Util 'rand_between';
#use Text::CSV_XS 'csv';

sub perl_mean {
	my @n = map { ref($_) eq 'ARRAY' ? @$_ : $_ } @_;
	my $current_sub = ( split( /::/, ( caller(0) )[3] ) )[-1];
	die "$current_sub needs >= 1 element in the array" if scalar @n < 1;
	return sum(@n) / scalar @n;
}
sub perl_sd {
	my @n = map { ref($_) eq 'ARRAY' ? @$_ : $_ } @_;
	my $current_sub = ( split( /::/, ( caller(0) )[3] ) )[-1];
	die "$current_sub needs >= 2 elements in the array" if scalar @n < 2;
	my $mean = sum(@n) / scalar @n;
	my $standard_deviation = 0;
	foreach my $element (@n) {
		$standard_deviation += ($element-$mean)**2;
	}
	return sqrt($standard_deviation/((scalar @n)-1));
}
my @x = map {rand_between(-5, 5)} 0..99999;
my $max = 999;
my $t0 = Time::HiRes::time();
for (my $n = 0; $n < $max; $n++) {
	perl_mean( \@x );
}
my $t1 = Time::HiRes::time();
my $run0 = $t1-$t0;
printf("perl mean did %lf seconds\n", $run0);
#-----------
$t0 = Time::HiRes::time();
for (my $n = 0; $n < $max; $n++) {	
	mean( \@x );
}
$t1 = Time::HiRes::time();
my $run1 = $t1-$t0;
printf("XS mean did %lf seconds\n", $run1);
printf("2nd/1st = %lf; 1st/2nd = %lf\n", $run1/$run0, $run0/$run1);
#-------------------
# test stdev
#-------------------
$t0 = Time::HiRes::time();
for (my $n = 0; $n < $max; $n++) {
	perl_sd( \@x );
}
$t1 = Time::HiRes::time();
$run0 = $t1-$t0;
printf("perl mean did %lf seconds\n", $run0);
#-----------
$t0 = Time::HiRes::time();
for (my $n = 0; $n < $max; $n++) {	
	sd( \@x );
}
$t1 = Time::HiRes::time();
$run1 = $t1-$t0;
printf("XS sd did %lf seconds\n", $run1);
printf("2nd/1st = %lf; 1st/2nd = %lf\n", $run1/$run0, $run0/$run1);
#-----
my @large_data = (1000000000.1, 1000000000.2, 1000000000.3);
# The variance of (0.1, 0.2, 0.3) is exactly 0.01.
say var(@large_data) . ' ?= 0.01';#, 'var: handles large magnitude data cleanly' );
say sd(@large_data) . ' ?= 0.1';
#----------
#my $aoh = csv( in => 't/HepatitisCdata.csv', headers => 'auto');
#p $aoh;
