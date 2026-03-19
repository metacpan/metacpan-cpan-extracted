#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

use Syntax::Feature::With qw(with);

# ------------------------------------------------------------
# Basic aliasing
# ------------------------------------------------------------
{
    my %h = ( a => 'b', x => 42 );
    my ($a, $x);

    my $result = with \%h, sub {
        return "$a|$x";
    };

    is($result, "b|42", 'basic aliasing works');
}

# ------------------------------------------------------------
# Read/write aliasing
# ------------------------------------------------------------
{
    my %h = ( a => 1, b => 2 );
    my ($a, $b);

    with \%h, sub {
        $a += 10;
        $b = 99;
    };

    is($h{a}, 11, 'writeback: $a += 10');
    is($h{b}, 99, 'writeback: $b = 99');
}

# ------------------------------------------------------------
# Invalid identifiers ignored
# ------------------------------------------------------------
{
    my %h = ( good => 1, '1bad' => 2, 'foo-bar' => 3 );
    my ($good);

    my $seen;
    with \%h, sub { $seen = $good };

    is($seen, 1, 'invalid identifiers ignored');
}

# ------------------------------------------------------------
# Undeclared lexicals remain undef
# ------------------------------------------------------------
{
    my %h = ( a => 123 );
    my $value;

    with \%h, sub {
        $value = $a;   # $a not declared
    };

    ok(!defined $value, 'undeclared lexical remains undef');
}

# ------------------------------------------------------------
# Error handling
# ------------------------------------------------------------
{
    my $err;
    eval { with([], sub {}) };
    $err = $@;
    like($err, qr/hashref/, 'dies on non-hashref');
}

{
    my %h = ( a => 1 );
    my $err;
    eval { with(\%h, "not a coderef") };
    $err = $@;
    like($err, qr/coderef/, 'dies on non-coderef');
}

done_testing();

