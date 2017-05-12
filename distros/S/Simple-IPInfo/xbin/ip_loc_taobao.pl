#!/usr/bin/perl

my $f = 'ip_loc_taobao.csv';
open my $fh, '>', $f;
for my $i ( 1 .. 255){
	open my $fhr, '<', "data/$i.csv";
	while(<$fhr>){
		print $fh $_;
	}
	close $fhr;
}
close $fh;
