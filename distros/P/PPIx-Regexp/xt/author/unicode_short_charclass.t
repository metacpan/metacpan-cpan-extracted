package main;

use 5.006;

use strict;
use warnings;

use PPIx::Regexp;
use Test::More 0.88;	# Because of done_testing();

note <<'EOD';

Scraping perluniprops seems fragile because it is, but I can not think
of better way to find out what all the single-character property names
are. If this breaks too often I may end up going to just matching
[[:upper:]] or something like that. Note to self: the relevant regular
expression is in PPIx::Regexp::Token::CharClass::Simple method
__PPIX_TOKENIZER__regexp()

EOD

my %prop;

foreach ( `perldoc -oText perluniprops` ) {
    m/ \\p [{] ( . ) [}] .*? \\p [{] ( .{2,}? ) [}] /smx
	or next;
    $prop{$1} ||= $2;
}

is_deeply \%prop, {
    C	=> 'Other',
    L	=> 'Letter',
    M	=> 'Mark',
    N	=> 'Number',
    P	=> 'Punct',
    S	=> 'Symbol',
    Z	=> 'Separator',
}, 'All single-character properties are accounted for';

foreach my $letter ( sort keys %prop ) {
    my $token = "\\p$letter";
    my $text = "/$token/";
    my $pre = PPIx::Regexp->new( $text );
    my $re = $pre->regular_expression();
    my @kids = $re->children();
    cmp_ok scalar( @kids ), '==', 1, "'$text' parsed to a single token";
    cmp_ok $kids[0]->content(), 'eq', $token, "'$text' contains token $token";
    isa_ok $kids[0], 'PPIx::Regexp::Token::CharClass::Simple',
	"Token $token";
}

done_testing;

1;

# ex: set textwidth=72 :
