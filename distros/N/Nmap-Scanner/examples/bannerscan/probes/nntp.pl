#!/usr/bin/perl
# Thu Jan 15 02:31:21 CET 2004
use Net::NNTP;
use Data::Dumper;

$host = $ARGV[0];

$nntp = Net::NNTP->new($host) or die "$!";
#print Dumper $host,$nntp->group("alt.binaries.e-book.technical");
print "$host: ";
map { print "$_ " } keys %{$nntp->list()};
print "\n";
