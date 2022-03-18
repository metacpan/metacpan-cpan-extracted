package main;

use 5.006;

use strict;
use warnings;

use PPI::Document;
use PPIx::QuoteLike;
use Test::More 0.88;	# Because of done_testing();

{
    note 'Parse "foo${bar}baz"';
    my $ppi = PPI::Document->new( \<<'EOD' );
#line 42 the_answer
"foo${bar}baz";
EOD
    my $qd = $ppi->find( 'PPI::Token::Quote::Double' );
    ok $qd, 'Found PPI::Token::Quote::Double';
    cmp_ok @{ $qd }, '==', 1,
	'Found exactly one PPI::Token:Quote::Double';
    my $pql = PPIx::QuoteLike->new( $qd->[0] );
    my @token = $pql->elements();
    cmp_ok scalar @token, '==', 6, 'Found 6 tokens in string';
    is_deeply $token[0]->location(), [ 2, 1, 1, 42, 'the_answer' ],
	q<Token 0 ('') location>;
    is_deeply $token[1]->location(), [ 2, 1, 1, 42, 'the_answer' ],
	q<Token 1 ('"') location>;
    is_deeply $token[2]->location(), [ 2, 2, 2, 42, 'the_answer' ],
	q<Token 2 ('foo') location>;
    is_deeply $token[3]->location(), [ 2, 5, 5, 42, 'the_answer' ],
	q<Token 3 ('${bar}') location>;
    is_deeply $token[4]->location(), [ 2, 11, 11, 42, 'the_answer' ],
	q<Token 4 ('baz') location>;
    cmp_ok $token[4]->line_number(), '==', 2,
	q<Token 4 ('baz') line_number()>;
    cmp_ok $token[4]->column_number(), '==', 11,
	q<Token 4 ('baz') column_number()>;
    cmp_ok $token[4]->visual_column_number(), '==', 11,
	q<Token 4 ('baz') visual_column_number()>;
    cmp_ok $token[4]->logical_line_number(), '==', 42,
	q<Token 4 ('baz') logical_line_number()>;
    cmp_ok $token[4]->logical_filename(), 'eq', 'the_answer',
	q<Token 4 ('baz') logical_filename()>;
    is_deeply $token[5]->location(), [ 2, 14, 14, 42, 'the_answer' ],
	q<Token 5 ('"') location>;
    is_deeply $pql->location(), [ 2, 1, 1, 42, 'the_answer' ],
	q<String location>;
    cmp_ok $pql->line_number(), '==', 2, q<String line_number()>;
    cmp_ok $pql->column_number(), '==', 1, q<String column_number()>;
    cmp_ok $pql->visual_column_number(), '==', 1,
	q<String visual_column_number()>;
    cmp_ok $pql->logical_line_number(), '==', 42,
	q<String logical_line_number()>;
    cmp_ok $pql->logical_filename(), 'eq', 'the_answer',
	q<String logical_filename()>;

    note q<PPI document corresponding to '${bar}'>;
    my $ppi2 = $token[3]->ppi();
    @token = $ppi2->tokens();
    cmp_ok scalar @token, '==', 1, 'Interpolation PPI has 1 token';
    is_deeply $token[0]->location(), [ 2, 5, 5, 42, 'the_answer' ],
	q<Token 0 ('$bar') location>;
}

{
    note <<'EOD';
Parse $var = "\t$x\t$xx\t$xxx\t\t"; with literal tabs
NOTE that tab widths other than 1 are unsupported by PPI as of 1.272
EOD
    my $doc = PPI::Document->new( \<<"EOD" );
#line 31 "Halloween"
\$var = "\t\$x\t\$xx\t\$xxx\t\t";
EOD
    $doc->tab_width( 8 );
    my $quote = $doc->find( 'PPI::Token::Quote::Double' );
    ok $quote, 'Found PPI::Token::Regexp::Match';
    cmp_ok @{ $quote }, '==', 1,
	'Found exactly one PPI::Token::Regexp::Match';
    my $ql = PPIx::QuoteLike->new( $quote->[0] );
    my @token = $ql->elements();
    cmp_ok scalar @token, '==', 10, 'Found 10 tokens in quote';
    is_deeply $token[0]->location(), [ 2, 8, 8, 31, 'Halloween' ],
	q<Token 0 ('') location>;
    is_deeply $token[1]->location(), [ 2, 8, 8, 31, 'Halloween' ],
	q<Token 1 ('"') location>;
    is_deeply $token[2]->location(), [ 2, 9, 9, 31, 'Halloween' ],
	q<Token 2 ('\\t') location>;
    is_deeply $token[3]->location(), [ 2, 10, 17, 31, 'Halloween' ],
	q<Token 3 ('$x') location>;
    is_deeply $token[4]->location(), [ 2, 12, 19, 31, 'Halloween' ],
	q<Token 4 ('\\t') location>;
    is_deeply $token[5]->location(), [ 2, 13, 25, 31, 'Halloween' ],
	q<Token 5 ('$xx') location>;
    is_deeply $token[6]->location(), [ 2, 16, 28, 31, 'Halloween' ],
	q<Token 6 ('\t') location>;
    is_deeply $token[7]->location(), [ 2, 17, 33, 31, 'Halloween' ],
	q<Token 7 ('$xxx') location>;
    is_deeply $token[8]->location(), [ 2, 21, 37, 31, 'Halloween' ],
	q<Token 8 ('\t\t') location>;
    is_deeply $token[9]->location(), [ 2, 23, 49, 31, 'Halloween' ],
	q<Token 9 ('"') location>;

}

done_testing;

1;

# ex: set textwidth=72 :
