#!/usr/bin/perl

use Test::More tests => 0x3004;

use strict;
use warnings;
no warnings 'syntax';

BEGIN {
    use_ok ('Regexp::CharClasses')
};

my @left  = qw !( [ < {!;
my @right = qw !) ] > }!;
my %left  = map {($_ => 1)} @left;
my %right = map {($_ => 1)} @right;

foreach my $l (@left) {
    ok $l =~ /^\p{IsLeftParen}$/, "Left paren $l";
    ok $l =~ /^\p{IsParen}$/, "Paren $l";
}

foreach my $r (@right) {
    ok $r =~ /^\p{IsRightParen}$/, "Right paren $r";
    ok $r =~ /^\p{IsParen}$/, "Paren $r";
}

foreach my $c (0x00 .. 0x1000) {
    my $char = chr $c;
    my $h    = sprintf "%04x" => $c;
    ok $char =~ /^\P{IsLeftParen}$/,  "\\x{$h} is not a left paren"
               unless $left {$char};
    ok $char =~ /^\P{IsRightParen}$/, "\\x{$h} is not a right paren"
               unless $right {$char};
    ok $char =~ /^\P{IsParen}$/, "\\x{$h} is not a paren"
               unless $right {$char} || $left {$char};
}


__END__
