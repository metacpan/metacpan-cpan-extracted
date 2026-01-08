#!/usr/bin/env perl
use strict;
use warnings;

use Retry::Policy;

my $p = Retry::Policy->new(
    max_attempts  => 5,
    base_delay_ms => 10,     # keep it quick
    max_delay_ms  => 50,
    jitter        => 'none', # deterministic output
    on_retry      => sub {
        my (%i) = @_;
        print "retry attempt=$i{attempt} delay_ms=$i{delay_ms} err=$i{error}\n";
    },
);

my $tries = 0;

my $out = $p->run(sub {
    my ($attempt) = @_;
    $tries++;
    die "transient\n" if $attempt < 3;
    return "ok";
});

print "result=$out tries=$tries\n";

