use strict;
use warnings;

use Test::More;

BEGIN{
    BAIL_OUT "A bug in Perl 5.20 regex compilation prevents the use of PPR under that release"
        if $] > 5.020 && $] < 5.022;
}

plan tests => 6;

use PPR::X;
use re 'eval';

my $MATCH_A_PERL_DOCUMENT = qr{
    \A (?&PerlEntireDocument) \Z

    (?(DEFINE)
        # Turn off built-in try/catch syntax...
        (?<PerlTryCatchFinallyBlock>   (?!)  )

        # Decanonize 'try' and 'catch' as reserved words ineligible for sub names...
        (?<PPR_X_non_reserved_identifier>
            (?! (?> for(?:each)?+ | while   | if    | unless | until | given | when   | default
                |   sub | format  | use     | no    | my     | our   | state  | defer | finally
                # Note: Removed 'try' and 'catch' which appear here in the original subrule
                |   (?&PPR_X_named_op)
                |   [msy] | q[wrxq]?+ | tr
                |   __ (?> END | DATA ) __
                )
                \b
            )
            (?>(?&PerlQualifiedIdentifier))
            (?! :: )
        )

        # Verify that try block is parsed as a sub call...
        (?<PerlCall>
            ((?&PerlStdCall))
            (?{ pass 'try {...} interpreted as sub call'   if substr($^N,0,3) eq 'try';
                pass 'catch {...} interpreted as sub call' if substr($^N,0,5) eq 'catch';
            })
        )
    )

    $PPR::X::GRAMMAR
}xms;

ok q{
        sub foo {
            try   { $x = 'maybe';     }
            catch { $x = 'maybe not'; };
        }
    } =~ $MATCH_A_PERL_DOCUMENT
        => 'Try/catch as statement';

ok q{
        sub foo {
            return try   { $x = 'maybe';     }
                   catch { $x = 'maybe not'; };
        }
    } =~ $MATCH_A_PERL_DOCUMENT
        => 'Try/catch as expression';


