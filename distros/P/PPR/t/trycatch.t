use strict;
use warnings;

use Test::More;

BEGIN{
    BAIL_OUT "A bug in Perl 5.20 regex compilation prevents the use of PPR under that release"
        if $] > 5.020 && $] < 5.022;
}

plan tests => 1;

use PPR;

my $MATCH_A_PERL_DOCUMENT = qr{
    \A (?&PerlEntireDocument) \Z

    (?(DEFINE)
        # Redefine this subrule to match TryCatch syntax...
        (?<PerlTryCatchFinallyBlock>
                    try                                 (?>(?&PerlOWS))
                    (?>(?&PerlBlock))
            (?:                                         (?>(?&PerlOWS))
                    catch                               (?>(?&PerlOWS))
                (?: \( (?>(?&PPR_balanced_parens)) \)   (?>(?&PerlOWS)) )?+
                    (?>(?&PerlBlock))
            )*+
        )
    )

    $PPR::GRAMMAR
}xms;


ok q{
        sub foo {
            try {
                do_something_risky();
            }
            catch (HTTPError $e where { $_->code >= 400 && $_->code <= 499 } ) {
                return "4XX error";
            }
            catch (HTTPError $e) {
                return "other http code";
            }
            catch {
                return "huh???";
            }
        }
    } =~ $MATCH_A_PERL_DOCUMENT;



