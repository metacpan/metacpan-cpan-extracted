#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

use Syntax::Feature::With qw(with);

# ------------------------------------------------------------
# Strict mode: all valid keys must have lexicals
# ------------------------------------------------------------
{
    my %h = ( a => 1, b => 2 );
    my ($a);

    my $err;
    eval {
        with -strict => \%h, sub {
            () = $a;   # ok
            $b;   # undeclared
        };
    };
    $err = $@;

    like($err, qr/strict mode/, 'strict mode detects missing lexical');
}

# ------------------------------------------------------------
# Strict mode passes when all lexicals exist
# ------------------------------------------------------------
{
    my %h = ( a => 1, b => 2 );
    my ($a, $b);

    my $ok = eval {
        with -strict => \%h, sub { $a + $b };
    };

	ok(!$@, 'strict mode passes when all lexicals declared');
}

done_testing();
