#!/usr/bin/perl

use strict;
use warnings;

use English qw(-no_match_vars);
use Test::More;
use Parse::EDID;

my %tests = (
    sample1 => [
        '00ffffffffffff0006af14a10000000001120103901a10780a50c59858528e2725505400000001010101010101010101010101010101ea1a007e502010303020360005a31000001aea1a007e502010303020360005a31000001a000000fe00593734374480423132314557300000000000000000000000000001010a202000a5'
    ],
    sample2 => [
        '00ffffffffffff0006af14a10000000001120103901a10780a50c59858528e2725505400000001010101010101010101010101010101ea1a007e502010303020360005a31000001aea1a007e502010303020360005a31000001a000000fe00593734374480423132314557300000000000000000000000000001010a202000a5',
        '00ffffffffffff0022f0f62601010101181401036e362378eece50a3544c99260f5054a56b8081408180a900a940b300d10001010101283c80a070b023403020360022602100001a000000fc004850204c5032343735770a2020000000fd0030551e5e15000a202020202020000000ff00434e43303234303343500a20200085'
    ]
);

plan tests => scalar keys %tests;

foreach my $test (keys %tests) {
    my $string = read_file("t/xrandr/$test");

    my @edids = find_edid_in_string($string);
    is_deeply(
        \@edids,
        [ map { binary($_) } @{$tests{$test}} ],
        "file $test: edids extraction"
    );
}
sub read_file {
    my ($file) = @_;
    local $RS;
    open (my $handle, '<', $file) or die "Can't open $file: $ERRNO";
    my $content = <$handle>;
    close $handle;
    return $content;
}

sub binary {
    my ($string) = @_;
    return pack("C*", map { hex($_) } $string =~ /(..)/g);
}
