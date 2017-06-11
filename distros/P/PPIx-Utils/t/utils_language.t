# Tests from Perl::Critic::Utils t/05_utils.t

use strict;
use warnings;

use PPI::Document;
use PPIx::Utils::Language ':all';
use Test::More;

test_precedence_of();

sub make_doc {
    my $code = shift;
    return PPI::Document->new(ref $code ? $code : \$code);
}

sub test_precedence_of {
    cmp_ok( precedence_of(q<*>), q[<], precedence_of(q<+>), 'Precedence' );

    my $code1 = '8 + 5';
    my $doc1  = make_doc($code1);
    my $op1   = $doc1->find_first('Token::Operator');

    my $code2 = '7 * 5';
    my $doc2  = make_doc($code2);
    my $op2   = $doc2->find_first('Token::Operator');

    cmp_ok( precedence_of($op2), '<', precedence_of($op1), 'Precedence (PPI)' );

    return;
}

# Tests from Perl::Critic::Utils::Perl t/05_utils_perl.t
{
    foreach my $sigil ( q<>, qw< $ @ % * & > ) {
        my $symbol = "${sigil}foo";
        is(
            symbol_without_sigil($symbol),
            'foo',
            "symbol_without_sigil($symbol)",
        );
    }
}

done_testing;
