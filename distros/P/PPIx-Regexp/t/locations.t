package main;

use 5.006;

use strict;
use warnings;

use PPI::Document;
use PPIx::Regexp;
use Test::More 0.88;	# Because of done_testing();

{
    note 'Parse s/\\n    foo\\n/bar/smxg';
    my $doc = PPI::Document->new( \<<'EOD' );
#line 42 the_answer
s/
    foo
/bar/smxg;
EOD
    my $subs = $doc->find( 'PPI::Token::Regexp::Substitute' );
    ok $subs, 'Found PPI::Token::Regexp::Substitute';
    cmp_ok @{ $subs }, '==', 1,
	'Found exactly one PPI::Token::Regexp::Substitute';
    my $re = PPIx::Regexp->new( $subs->[0] );
    my @token = $re->tokens();
    cmp_ok scalar @token, '==', 13, 'Found 13 tokens in regex';
    is_deeply $token[0]->location(), [ 2, 1, 1, 42, 'the_answer' ],
	q<Token 0 ('s') location>;
    cmp_ok $token[0]->line_number(), '==', 2,
	q<Token 0 ('s') line number>;
    cmp_ok $token[0]->column_number(), '==', 1,
	q<Token 0 ('s') column number>;
    cmp_ok $token[0]->visual_column_number(), '==', 1,
	q<Token 0 ('s') visual column number>;
    cmp_ok $token[0]->logical_line_number(), '==', 42,
	q<Token 0 ('s') logical line number>;
    cmp_ok $token[0]->logical_filename(), 'eq', 'the_answer',
	q<Token 0 ('s') logical file name>;
    is_deeply $token[1]->location(), [ 2, 2, 2, 42, 'the_answer' ],
	q<Token 1 ('/') location>;
    is_deeply $token[2]->location(), [ 2, 3, 3, 42, 'the_answer' ],
	q<Token 2 ("\\n    ") location>;
    is_deeply $token[3]->location(), [ 3, 5, 5, 43, 'the_answer' ],
	q<Token 3 ('f') location>;
    is_deeply $token[4]->location(), [ 3, 6, 6, 43, 'the_answer' ],
	q<Token 4 ('o') location>;
    is_deeply $token[5]->location(), [ 3, 7, 7, 43, 'the_answer' ],
	q<Token 5 ('o') location>;
    is_deeply $token[6]->location(), [ 3, 8, 8, 43, 'the_answer' ],
	q<Token 6 ("\n") location>;
    is_deeply $token[7]->location(), [ 4, 1, 1, 44, 'the_answer' ],
	q<Token 7 ('/') location>;
    is_deeply $token[8]->location(), [ 4, 2, 2, 44, 'the_answer' ],
	q<Token 8 ('b') location>;
    is_deeply $token[9]->location(), [ 4, 3, 3, 44, 'the_answer' ],
	q<Token 9 ('a') location>;
    is_deeply $token[10]->location(), [ 4, 4, 4, 44, 'the_answer' ],
	q<Token 10 ('r') location>;
    is_deeply $token[11]->location(), [ 4, 5, 5, 44, 'the_answer' ],
	q<Token 11 ('/') location>;
    is_deeply $token[12]->location(), [ 4, 6, 6, 44, 'the_answer' ],
	q<Token 12 ('smxg') location>;
    is_deeply $re->location(), [ 2, 1, 1, 42, 'the_answer' ],
	q<PPI::Regexp location>;
}

{
    note 'Parse s/([[:alpha:]]+)/ reverse $1 /smxge';
    my $doc = PPI::Document->new( \<<'EOD' );
#line 86 "get_smart"
s/([[:alpha:]]+)/ reverse $1 /smxge;
EOD
    my $subs = $doc->find( 'PPI::Token::Regexp::Substitute' );
    ok $subs, 'Found PPI::Token::Regexp::Substitute';
    cmp_ok @{ $subs }, '==', 1,
	'Found exactly one PPI::Token::Regexp::Substitute';
    my $re = PPIx::Regexp->new( $subs->[0] );
    my @token = $re->tokens();
    cmp_ok scalar @token, '==', 12, 'Found 12 tokens in regex';
    is_deeply $token[0]->location(), [ 2, 1, 1, 86, 'get_smart' ],
	q<Token 0 ('s') location>;
    is_deeply $token[1]->location(), [ 2, 2, 2, 86, 'get_smart' ],
	q<Token 1 ('/') location>;
    is_deeply $token[2]->location(), [ 2, 3, 3, 86, 'get_smart' ],
	q<Token 2 ('(') location>;
    is_deeply $token[3]->location(), [ 2, 4, 4, 86, 'get_smart' ],
	q<Token 3 ('[') location>;
    is_deeply $token[4]->location(), [ 2, 5, 5, 86, 'get_smart' ],
	q<Token 4 ('[:alpha:]') location>;
    is_deeply $token[5]->location(), [ 2, 14, 14, 86, 'get_smart' ],
	q<Token 5 (']') location>;
    is_deeply $token[6]->location(), [ 2, 15, 15, 86, 'get_smart' ],
	q<Token 6 ('+') location>;
    is_deeply $token[7]->location(), [ 2, 16, 16, 86, 'get_smart' ],
	q<Token 7 (')') location>;
    is_deeply $token[8]->location(), [ 2, 17, 17, 86, 'get_smart' ],
	q<Token 8 ('/') location>;
    is_deeply $token[9]->location(), [ 2, 18, 18, 86, 'get_smart' ],
	q<Token 9 (' reverse $1 ') location>;
    is_deeply $token[10]->location(), [ 2, 30, 30, 86, 'get_smart' ],
	q<Token 10 ('/') location>;
    is_deeply $token[11]->location(), [ 2, 31, 31, 86, 'get_smart' ],
	q<Token 11 ('smxge') location>;

    note q<PPI document corresponding to ' reverse $1 '>;
    my $code = $token[9]->ppi();
    @token = $code->tokens();
    cmp_ok scalar @token, '==', 5,
	'Found 5 PPI tokens in replacement expression';
    is_deeply $token[0]->location(), [ 2, 1, 1, 86, 'get_smart' ],
	q<Token 0 ('   ...') location>;
    is_deeply $token[1]->location(), [ 2, 19, 19, 86, 'get_smart' ],
	q<Token 1 ('reverse') location>;
    note <<'EOD';
The above is not the same as token 9 of the RE because of the leading
white space in the expression.
EOD
    is_deeply $token[2]->location(), [ 2, 26, 26, 86, 'get_smart' ],
	q<Token 2 (' ') location>;
    is_deeply $token[3]->location(), [ 2, 27, 27, 86, 'get_smart' ],
	q<Token 3 ('$1') location>;
    is_deeply $token[4]->location(), [ 2, 29, 29, 86, 'get_smart' ],
	q<Token 4 (' ') location>;
}

done_testing;

1;

# ex: set textwidth=72 :
