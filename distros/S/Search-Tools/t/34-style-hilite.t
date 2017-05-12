use Test::More tests => 6;
use strict;

use Data::Dump qw( dump );

use_ok('Search::Tools::HiLiter');
use_ok('Search::Tools::Snipper');

my $text = <<EOF;
when in the course of human events
you need to create a test to span the ages and prove
your style is still hip, still happening,
that style isn't outmoded but something to
embrace.
EOF

my @q = ('span your style');

ok( my $query = Search::Tools->parser->parse( join( ' ', @q ) ),
    "new query" );
ok( my $h = Search::Tools::HiLiter->new( query => $query ), "hiliter" );

ok( my $l = $h->light($text), "light" );

#diag($l);

unlike( $l, qr/<span <span/, "no double-dipping by hiliter" );
