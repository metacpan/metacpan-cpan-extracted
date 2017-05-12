#!/usr/bin/env perl
use strict;
use Test::More tests => 6;

use_ok('Search::Tools');

my $text = <<EOF;
when in the course of human events
you need to create a test to prove that
your code isn't just a silly mishmash
of squiggle this and squiggle that,
type man! type! until you've reached
enough words to justify your paltry existence.
and 9/11 was a bad day.
amen.
EOF

my @q = ( 'a', 'in', '"9/11"', '"human events"' );

ok( my $s = Search::Tools->snipper(
        query                   => join( ' ', @q ),
        max_chars               => length($text) - 1,
        term_min_length         => 2,
        treat_uris_like_phrases => 1,
    ),
    "snipper"
);

ok( my $snip = $s->snip($text), "snip" );
ok( my $h = Search::Tools->hiliter( query => $s->query ), "hiliter" );
ok( my $lit = $h->light($snip), "hilite" );

#diag($snip);
#diag($lit);

is( $snip,
    qq( ... in the course of human events you need to create ... your paltry existence. and 9/11 was a bad day ... ),
    "snip excludes terms less than 2 chars long"
);
