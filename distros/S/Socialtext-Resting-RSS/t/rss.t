#!/usr/bin/perl
use strict;
use warnings;
use Test::More qw/no_plan/;
use Test::Exception;

BEGIN {
    use_ok 'Socialtext::Resting::RSS';
}

Sanity: {
    my %o;
    throws_ok { Socialtext::Resting::RSS->new(%o) } qr/rester is mandatory/;
    $o{rester} = 1;
    throws_ok { Socialtext::Resting::RSS->new(%o) } qr/output is mandatory/;
    $o{output} = 1;
    my $rss = Socialtext::Resting::RSS->new(%o);
    isa_ok $rss, 'Socialtext::Resting::RSS';
}
