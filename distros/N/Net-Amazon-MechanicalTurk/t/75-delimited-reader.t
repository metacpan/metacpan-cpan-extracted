#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 2;
BEGIN { push(@INC, "lib", "t"); }
use Net::Amazon::MechanicalTurk::DelimitedReader;
use Data::Dumper;

my @expected = (
    ['Name', 'Age'],
    ['Castillo,Bryan', 30],
    ["\"Meagan\tC\"", 29],
    ["Tobin", "Is\n  10\n\nYears old"],
    ["Charles", 6],
    ["James", 3],
    [''],
    ['',''],
    [''],
    ['Bob'],
    ['']
);

my $file;
my $reader;
my @results;


@results = ();
$file = "t/data/75-delimited-reader.csv";
$reader = Net::Amazon::MechanicalTurk::DelimitedReader->new(
    file => $file
);
while (my $row = $reader->next) {
    push(@results, $row);
}
is_deeply(\@expected, \@results);

@results = ();
$file = "t/data/75-delimited-reader.txt";
$reader = Net::Amazon::MechanicalTurk::DelimitedReader->new(
    file => $file,
    fieldSeparator => "\t"
);
while (my $row = $reader->next) {
    push(@results, $row);
}
is_deeply(\@expected, \@results);

