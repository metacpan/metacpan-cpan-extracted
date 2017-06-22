use warnings;
use strict;

use Test::More;

plan tests => 5;


use PPR::X;

ok '>> 1 ^^ 2' =~ m{

    \A (?&PerlExpression) \Z

    (?(DEFINE)
        (?<PerlInfixBinaryOperator>
            \^\^ | (?&PerlStdInfixBinaryOperator)
        )

        (?<PerlPrefixUnaryOperator>
            >> | (?&PerlStdPrefixUnaryOperator)
        )
    )

    $PPR::X::GRAMMAR

}xms => 'Extended expression matched';

ok q[ no!!! { say 'failed'; } ] =~ m{

    \A (?&PerlOWS) (?&PerlStatement) (?&PerlOWS) \Z

    (?(DEFINE)
        (?<PerlStatement>
            no [!]++  (?&PerlOWS)  (?&PerlBlock)
        |
            (?&PerlStdStatement)
        )
    )


    $PPR::X::GRAMMAR
}xms => 'Extended statement matched';


ok q[ use Discretion; no!!! { say 'failed'; }  sub foo { 'bar' }  ] =~ m{

    \A (?&PerlOWS) (?&PerlDocument) (?&PerlOWS) \Z

    (?(DEFINE)
        (?<PerlStatement>
            no [!]++  (?&PerlOWS)  (?&PerlBlock)
        |
            (?&PerlStdStatement)
        )
    )


    $PPR::X::GRAMMAR
}xms => 'Extended statement within document matched';


my $GRAMMATICA = qr{

    # Verbum sapienti satis est...
    (?(DEFINE)

        # Iunctiones...
        (?<PerlLowPrecedenceInfixOperator>
            atque | vel | aut
        )

        # Contradicetur...
        (?<PerlLowPrecedenceNotExpression>
            (?: non  (?&PerlOWS) )*+  (?&PerlCommaList)
        )
    )

    $PPR::X::GRAMMAR
}x;

ok '$a and not $b or $y xor $z' !~ m{ \A (?&PerlDocument) \Z  $GRAMMATICA }xms,
    => 'Did not match English connectives';

ok '$a atque non $b vel $y aut $z' =~ m{ \A (?&PerlDocument) \Z  $GRAMMATICA }xms,
    => 'Matched Latin connectives';


done_testing();

