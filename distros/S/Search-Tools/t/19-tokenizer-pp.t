use strict;
use warnings;
use Data::Dump qw( dump );
use Test::More tests => 1263;


# http://code.google.com/p/test-more/issues/detail?id=46
binmode Test::More->builder->output,         ":utf8";
binmode Test::More->builder->failure_output, ":utf8";

use_ok('Search::Tools');
use_ok('Search::Tools::Tokenizer');
use Search::Tools::UTF8;

# snipper example
my $handler_count = 0;

sub handler {

    #warn "handler called";
    $handler_count++;
    ok( $_[0] eq $_[0], "eq overload" );
    ok( $_[0] cmp 'ZZZZ', "cmp overload" );
    ok( $_[0] =~ $_[0]->str, "stringify overload" );
    ok( $_[0], "bool overload" );
}

my $simple = "foo bar baz";

my $str = <<EOF;
these are some words we expect (don't we?) the
tokenizer to handle with aplomb.
If it can't, well, then... back to the drawing board!
EOF

my $str2 = <<EOF;
!@#0^    some strings with non-token at the start and end !@#0^&*() 
EOF

my $greek = Search::Tools->slurp('t/docs/greek_and_ojibwe.txt');

ok( my $tokenizer = Search::Tools::Tokenizer->new(), "new tokenizer" );

ok( my $simple_tokens = $tokenizer->tokenize_pp( $simple, \&handler ),
    "tokenize simple" );
is( check_tokens($simple_tokens), 5,       "5 simple tokens" );
is( $simple_tokens,               $simple, "simple_tokens->str" );

ok( my $tokens = $tokenizer->tokenize_pp($str), "tokenize str for tokens" );
is( check_tokens($tokens), 48,   "str count" );
is( $tokens->str,          $str, "tokens->str" );

ok( my $tokens2 = $tokenizer->tokenize_pp($str2), "tokenize str2" );
is( check_tokens($tokens2), 23,    "str2 count" );
is( $tokens2->str,          $str2, "tokens2->str" );
ok( my $grtokens = $tokenizer->tokenize_pp($greek), "tokenize greek" );
is( check_tokens($grtokens), 99,     "grtokens count" );
is( $grtokens->str,          $greek, "grtokens->str" );

###############################################################
# use regex matching one char (e.g. simple chinese tokenizer)
my $chinese = '布朗在迅速跳下懒狐狗';
ok( my $cjk_tokenizer = Search::Tools::Tokenizer->new( re => qr/\w/ ),
    "cjk_tokenizer" );
ok( my $cjk_tokens = $cjk_tokenizer->tokenize_pp( $chinese, \&handler ),
    "tokenize chinese" );
is( check_tokens($cjk_tokens), 10,       "check cjk_tokens" );
is( $cjk_tokens,               $chinese, "cjk_tokens->str" );

# try cjk against ascii
my $ascii = 'abc';
ok( my $ascii_tokens = $cjk_tokenizer->tokenize_pp($ascii),
    "tokenize ascii" );
is( check_tokens($ascii_tokens), 3,      "check ascii tokens" );
is( $ascii_tokens,               $ascii, "ascii_tokens->str" );

is( $handler_count, 13, "handler_count" );

sub check_tokens {
    my $tokens = shift;

    #dump $tokens;
    my $count = 0;
    while ( my $tok = $tokens->next ) {
        ok( length( $tok->str ), "tok->str" );

        #diag( '[' . $tok->str . ']' );
        cmp_ok( $tok->len,   '>=', 1,         "tok->len >= 1" );
        cmp_ok( $tok->u8len, '<=', $tok->len, "u8len <= len" );
        ok( defined $tok->pos,          "token pos" );
        ok( defined $tok->set_match(0), "set match" );
        ok( defined $tok->set_hot(1),   "set hot" );

        $count++;
    }

    is( $count,       $tokens->num, "count == num" );
    is( $tokens->pos, $tokens->num, "pos == num-1 when all seen" );
    is( $tokens->len, $tokens->num, "len == num" );
    is( scalar( @{ $tokens->as_array } ), $count, "get as_array" );
    ok( defined $tokens->get_token(0), "get first token" );
    ok( my $matches = $tokens->matches, "get matches" );

    # only place this would not be true
    # is an original string of one token
    cmp_ok( scalar(@$matches), '<', $count, "matches < count" );

    ok( my $last_tok = $tokens->prev, "get last token" );
    is( $tokens->pos, $tokens->num - 1, "pos decremented" );
    is( $last_tok,    $tokens->next,    "really got last token" );

    #dump($tokens);
    return $count;

}
