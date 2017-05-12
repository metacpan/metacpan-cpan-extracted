#!/home/ben/software/install/bin/perl
use warnings;
use strict;
binmode STDOUT, ":utf8";
use FindBin '$Bin';
use Table::Readable qw/read_table/;
my @list = read_table ("$Bin/file.txt");
for my $entry (@list) {
    for my $k (keys %$entry) {
	print "$k $entry->{$k}\n";
    }
}

