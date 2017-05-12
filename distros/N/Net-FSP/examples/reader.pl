#! /usr/bin/perl
use strict;
use warnings;
use lib 'lib';
use Net::FSP;

my $fsp = Net::FSP->new('localhost', { remote_port => 2000 });

my $fh = $fsp->open_file('abby', '<');

while(<$fh>) {
	print;
}
