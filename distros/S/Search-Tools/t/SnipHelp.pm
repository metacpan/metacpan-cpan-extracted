package SnipHelp;
use Test::More;
use strict;
use warnings;
use Data::Dump qw( dump );

use Search::Tools::XML;
use Search::Tools::Snipper;
use Search::Tools::UTF8;

my $num_tests = 18;

sub test {
    my ( $file, $q, $snipper_type ) = @_;
    use_ok('Search::Tools');
    use_ok('Search::Tools::Snipper');
    use_ok('Search::Tools::HiLiter');
    use_ok('Search::Tools::XML');
    ok( my $XML   = Search::Tools::XML->new, "new XML object" );
    ok( my $html  = Search::Tools->slurp($file),        "read buf" );
    ok( my $plain = $XML->strip_html($html), "strip_html" );

    if ( $XML->looks_like_html($html) ) {
        cmp_ok( $html, 'ne', $plain, "strip_html ok" );
        if ( $XML->looks_like_html($plain) ) {
            fail("plain text has no html");
        }
        else {
            pass("plain text has no html");
        }
    }
    else {
        pass("strip_html skipped");
        pass("strip_html skipped");
    }
    ok( my $qparser = Search::Tools->parser(), "new qparser" );
    ok( my $query   = $qparser->parse($q),     "new query" );
    ok( my $snipper = Search::Tools::Snipper->new(
            query     => $query,
            occur     => 1,
            context   => 25,
            max_chars => 190,
            type      => $snipper_type,    # make explicit
                                           #escape    => 1,
        ),
        "new snipper"
    );
    ok( my $hiliter = Search::Tools::HiLiter->new(
            query => $query,
            tag   => "b",
            class => "x",
            tty   => $snipper->debug,
        ),
        "new hiliter"
    );

    ok( my $snip    = $snipper->snip($plain),  "snip plain" );
    ok( my $hilited = $hiliter->hilite($snip), "hilite" );
    ok( my @snip_words  = split( m/\W+/, $snip ),  "split snipped words" );
    ok( my @plain_words = split( m/\W+/, $plain ), "split plain words" );
    if ( scalar(@plain_words) > $snipper->context ) {

        # the -5 fuzziness is to allow for edge cases with lots
        # of treat_like_phrase matches, like email address, urls, etc.
        # these generate a lot of tokens in tokenizer,
        # so the context is fairly high
        # but our QueryParser regex (and the one above) doesn't catch them.
        cmp_ok(
            scalar(@snip_words), '>=',
            ( $snipper->context - 5 ),
            "context length >="
        );
        #diag( "context == " . scalar(@snip_words) );
    }
    else {
        cmp_ok( scalar(@snip_words), '==', scalar(@plain_words),
            "context length ==" );
    }

    return ( $snip, $hilited, $query, $plain, $num_tests );
}

1;
