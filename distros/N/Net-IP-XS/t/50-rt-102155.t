#!/usr/bin/env perl

use warnings;
use strict;

use Config;
use if $Config{'useithreads'}, 'threads';
use Test::More;

BEGIN {
    if (not $Config{'useithreads'}) {
        plan skip_all => "Perl not compiled with 'useithreads'";
    } else {
        plan tests => 1;
    }
};
        
use Net::IP::XS;

my $i = Net::IP::XS->new('::1');
for my $j (1..10) {
    async {};
}
for my $thread (threads->list()) {
    $thread->join();
}
ok(1, "Completed thread test successfully");

1;
