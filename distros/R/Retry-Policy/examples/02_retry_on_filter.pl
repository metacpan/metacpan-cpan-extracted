#!/usr/bin/env perl
use strict;
use warnings;

use Retry::Policy;

my $p = Retry::Policy->new(
    max_attempts  => 5,
    base_delay_ms => 10,
    max_delay_ms  => 50,
    jitter        => 'none',
    retry_on      => sub {
        my ($err, $attempt) = @_;
        return ($err =~ /timeout/i) ? 1 : 0;
    },
    on_retry      => sub {
        my (%i) = @_;
        print "retry attempt=$i{attempt} delay_ms=$i{delay_ms} err=$i{error}\n";
    },
);

my $case = shift(@ARGV) || 'timeout';

my $out = eval {
    $p->run(sub {
        my ($attempt) = @_;
        die "timeout\n" if $case eq 'timeout' && $attempt < 3;
        die "bad request\n" if $case eq 'bad';
        return "ok";
    });
};

if ($@) {
    chomp $@;
    print "failed: $@\n";
    exit 1;
}

print "result=$out\n";
exit 0;

