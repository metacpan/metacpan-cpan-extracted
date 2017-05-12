#!/usr/bin/perl
use File::Find;

find(\&print_matches, @ARGV);

sub print_matches {
	print $File::Find::name, "\t", -s _, "\n" if
		$File::Find::name =~ /\.(mp3|mpe?g|asf|avi|jpe?g)$/i &&
		-f $File::Find::name &&
		-s _;
}
