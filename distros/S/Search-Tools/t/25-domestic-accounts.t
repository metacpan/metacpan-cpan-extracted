#!/usr/bin/env perl

use strict;
use Search::Tools;
use Search::Tools::XML;
use Test::More tests => 10;

use Data::Dump qw( dump );

#dump( $hiliter->query );

ok( my $buf = Search::Tools->slurp('t/docs/domestic-accounts.html'), "read buf" );
ok( $buf = Search::Tools::XML->strip_markup($buf), "strip markup" );

#diag( $buf );

ok( my $snipper = Search::Tools->snipper(
        query        => q(+domestic +accounts),
        occur        => 1,
        context      => 25,
        max_chars    => 190,
        as_sentences => 1,
    ),
    "create new snipper"
);

ok( my $snip = $snipper->snip($buf), 'snip buf' );

#diag($snip);
is( $snip,
    q(Background Over a number of years, municipal accounts ol some domestic consumers that do not qualify for free basic services in terms of Council's Assistance to the Poor Policy, have been reflecting very high balances for water consumption.),
    "got snip"
);

ok( $snipper = Search::Tools->snipper(
        query        => q(+domestic +accounts),
        occur        => 1,
        context      => 25,
        max_chars    => 190,
        as_sentences => 0,
    ),
    "create new snipper"
);

#dump( $hiliter->query );

ok( $snip = $snipper->snip($buf), 'snip buf' );

#diag($snip);
is( $snip,
    q( ... high outstanding amounts for water. Background Over a number of years, municipal accounts ol some domestic consumers that do not qualify for free basic services in terms of ... ),
    "got snip"
);
ok( my @snip_words = split( m/\W+/, $snip ), "split snip" );
cmp_ok( scalar(@snip_words), '>=', $snipper->context, "number of context" );
