#!/usr/bin/perl

use Test::More tests => 0x1002;

use strict;
use warnings;
no warnings 'syntax';

BEGIN {
    use_ok ('Regexp::CharClasses')
};

my @sigils = qw [$ @ % & *];
my %sigils = map {($_ => 1)} @sigils;

foreach my $s (@sigils) {
    ok $s =~ /^\p{IsPerlSigil}$/, "sigil $s";
}

foreach my $c (0x00 .. 0x1000) {
    my $char = chr $c;
    next if $sigils {$char};
    my $h    = sprintf "%04x" => $c;
    ok $char =~ /^\P{IsPerlSigil}$/, "\\x{$h} is not a sigil";
}

__END__
