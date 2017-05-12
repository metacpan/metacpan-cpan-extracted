#!perl

use strict;
use warnings;

package T1;		# Parse::Lex creates $T1::VALUE, need new package to avoid colision
use Test::More;
use_ok 'Parse::Lex';

isa_ok my $lex = Parse::Lex->new(VALUE => 'blarg(?!blarg)'), 'Parse::Lex';
is $lex->from("blarg"), $lex, "init lexer";
isa_ok my $token = $lex->next, 'Parse::Token';
is $token->text, "blarg", "got token";

package T2;		# Parse::Lex creates $T2::VALUE, need new package to avoid colision
use Test::More;
use_ok 'Parse::Lex';

my $re = qr/blarg(?!blarg)/;
isa_ok $lex = Parse::Lex->new(VALUE => $re), 'Parse::Lex';
is $lex->from("blarg"), $lex, "init lexer with qr//";
isa_ok $token = $lex->next, 'Parse::Token';
is $token->text, "blarg", "got token";

done_testing;
