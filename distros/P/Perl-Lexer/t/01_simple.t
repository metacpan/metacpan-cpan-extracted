use strict;
use Test::More;

use Perl::Lexer;

subtest '"5963"' => sub {
    my @tokens = @{Perl::Lexer->new->scan_string('5963')};
    is 0+@tokens, 1;
    isa_ok $tokens[0], 'Perl::Lexer::Token';
    is $tokens[0]->name,   'THING';
    is $tokens[0]->type,   TOKENTYPE_OPVAL;
    isa_ok $tokens[0]->yylval, 'B::OP';
    is $tokens[0]->yylval->name, 'const';
    is $tokens[0]->yylval->sv->int_value, 5963;
};

subtest 'use Foo 0.01' => sub {
    my @tokens = @{Perl::Lexer->new->scan_string('use Foo 0.01')};
    is 0+@tokens, 3;
    subtest 'first token' => sub {
        isa_ok $tokens[0], 'Perl::Lexer::Token';
        is $tokens[0]->name,   'USE';
        is $tokens[0]->type,   TOKENTYPE_IVAL;
        is $tokens[0]->yylval, 1;
    };

    subtest 'second' => sub {
        isa_ok $tokens[1], 'Perl::Lexer::Token';
        like $tokens[1]->name,   qr/\A(?:BARE)?WORD\z/;
        is $tokens[1]->type,   TOKENTYPE_OPVAL;
        is $tokens[1]->yylval_svop, '0.01';
    };

    subtest 'third' => sub {
        isa_ok $tokens[2], 'Perl::Lexer::Token';
        like $tokens[2]->name,   qr/\A(?:BARE)?WORD\z/;
        is $tokens[2]->type,   TOKENTYPE_OPVAL;
        is $tokens[2]->yylval_svop, 'Foo';
    };
};

subtest '3*5+2/4' => sub {
    my @tokens = @{Perl::Lexer->new->scan_string('3*5+2/4')};
    is 0+@tokens, 7;
    subtest 'tokens' => sub {
        is $tokens[0]->name,   'THING';
        is $tokens[0]->yylval->sv->int_value, 3;

        is $tokens[1]->name,   'MULOP';
        is $tokens[1]->type, TOKENTYPE_OPNUM;

        is $tokens[2]->name,   'THING';
        is $tokens[2]->yylval->sv->int_value, 5;

        is $tokens[3]->name,   'ADDOP';
        is $tokens[3]->type, TOKENTYPE_OPNUM;

        is $tokens[4]->name,   'THING';
        is $tokens[4]->yylval->sv->int_value, 2;

        is $tokens[5]->name,   'MULOP';
        is $tokens[5]->type, TOKENTYPE_OPNUM;

        is $tokens[6]->name,   'THING';
        is $tokens[6]->yylval->sv->int_value, 4;
    };
};

done_testing;

