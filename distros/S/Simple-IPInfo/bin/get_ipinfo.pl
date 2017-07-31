#!/usr/bin/perl
use Simple::IPInfo;
use Encode::Locale;
use Encode;
use Data::Dumper;
use utf8;

binmode( STDIN,  ":encoding(console_in)" );
binmode( STDOUT, ":encoding(console_out)" );
binmode( STDERR, ":encoding(console_out)" );

my ($in) = @ARGV;
my $loc = get_ip_loc([ [ $in ] ], reserve_inet=>1);
my $as = get_ip_as([ [ $in ] ]);
print join(",", $in, @{$loc->[0]}[1 .. 7], @{$as->[0]}[1 .. 1]),"\n";
