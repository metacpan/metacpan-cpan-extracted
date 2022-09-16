use 5.010;
use warnings;

use Test::More;
plan tests => 1;

my $relation;
{
    use Regexp::Grammars;

    qr{
        <grammar: Main>

# FIX THIS (CURRENTLY NOT WORKING CORRECTLY)...
#        <debug: same>

        <objrule: Axiom::Expr=Relation>
            (?:
                \( <[args=Relation]> \) <.ImpliesToken> \( <[args=Relation]> \)
                <type=(?{ 'implies' })>
            |
                <[args=Expr]> <.EqualsToken> <[args=Expr]>
                <type=(?{ 'equals' })>
            )

        <token: ImpliesToken>   -\>
        <token: Expr>           [A-Z]
        <token: EqualsToken>    =
    }xms;

    $relation = qr{
        <extends: Main>
        <Relation>
    }xms;
}

ok '(A = B) -> (B = A)' =~ qr/\A$relation\Z/ => 'Correctly matched trailing autospace';
