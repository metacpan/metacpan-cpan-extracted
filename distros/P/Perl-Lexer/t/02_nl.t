use strict;
use warnings;
use utf8;
use Test::More;
use Perl::Lexer;

my $has_debug_token = $^V >= v5.33.6 ? 1 : 0;

subtest '1\n+\n3' => sub {
    my @tokens = @{Perl::Lexer->new->scan_string("1\n+\n3")};
    is 0+@tokens, 3 + $has_debug_token;

    isa_ok $tokens[0], 'Perl::Lexer::Token';
    is $tokens[0]->name,   'THING';
    is $tokens[0]->type,   TOKENTYPE_OPVAL;
    isa_ok $tokens[0]->yylval, 'B::SVOP';
    is $tokens[0]->yylval_svop, 1;

    is $tokens[1]->name,   'ADDOP';

    is $tokens[2]->name,   'THING';
    is $tokens[2]->yylval_svop, 3;

    if ($has_debug_token) {
        is $tokens[3]->name, 'PERLY_SEMICOLON';
    }
};


done_testing;

