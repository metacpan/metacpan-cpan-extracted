#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 9;
use Search::Tools::XML;
use Search::Tools::UTF8;

my $txt = "FOR IMMEDIATE RELEASE&amp;#8232;
Music Festival
&amp;#8232;June 2011&amp;#8232;";

my $XML = Search::Tools::XML->new;

like( ' ',      qr/\s/, "ascii 32 == \\s" );
like( "\n",     qr/\s/, "ascii 10 == \\s" );
like( "\r",     qr/\s/, "ascii 13 == \\s" );
like( "\t",     qr/\s/, "ascii tab == \\s" );
like( "\x200b", qr/\s/, "\\x200b == \\s" );
like( "\x2028", qr/\s/, "\\x2028 == \\s" );

ok( is_valid_utf8($txt), "is_valid_utf8 pre strip_html" );
my $clean = $XML->strip_html( $txt, 1 );
ok( is_valid_utf8($clean), "is_valid_utf8 post strip_html" );
is( $clean,
    "FOR IMMEDIATE RELEASE Music Festival June 2011 ",
    "got clean text"
);

#debug_bytes($clean);
#diag($clean);
