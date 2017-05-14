#!/usr/bin/perl

=head1 NAME

t/test-dir-1.t - Postfix::Mailq test suite

=head1 DESCRIPTION

Tests count of messages in the "t/test-dir-1" directory

=cut

use strict;
use warnings;

use FindBin qw($Bin);
use Test::More tests => 3;
use Postfix::Mailq;

my $test_dir = "$Bin/test-dir-1";
ok(-d $test_dir, "test directory '$test_dir' found");

my $count = Postfix::Mailq::get_fast_count({
    spool_dir => $test_dir,
});
is_deeply($count, {
    incoming => 2,
    active => 2,
    deferred => 0,
    total => 4,
});

# Also take "hold" into account now
$count = Postfix::Mailq::get_fast_count({
    spool_dir => $test_dir,
    get_hold  => 1,
});
is_deeply($count, {
    incoming => 2,
    active => 2,
    deferred => 0,
    hold => 3,
    total => 7,
}, "get_hold flag is honored correctly");
