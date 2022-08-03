use strict;
use warnings;

use Test::More;

BEGIN{
    BAIL_OUT "A bug in Perl 5.20 regex compilation prevents the use of PPR under that release"
        if $] > 5.020 && $] < 5.022;
}

plan tests => 10;

use PPR::X;
use re 'eval';

my $METAREGEX = qr{
    \A \s* (?&PerlQuotelikeQR) \s* \Z
    (?{ ok 1 => $_ })

    (?(DEFINE)
        (?<PerlScalarAccessNoSpace>
            ((?&PerlStdScalarAccessNoSpace))
            (?{ fail "$^N should not match a (?&PerlScalarAccessNoSpace)"
                    if $^N eq '$('
                    || $^N eq '$|'
                    || $^N eq '$)';
            })
        )

        (?<PerlArrayAccessNoSpace>
            ((?&PerlStdArrayAccessNoSpace))
            (?{ fail "$^N should not match a (?&PerlArrayAccessNoSpace)"
                    if $^N eq '@('
                    || $^N eq '@|'
                    || $^N eq '@)';
            })
        )
    )

    $PPR::X::GRAMMAR;
}xms;

'qr{ $( ) }' =~ $METAREGEX;
'qr{ $| }' =~ $METAREGEX;
'qr{ ( $) }' =~ $METAREGEX;
'qr{ $_ }' =~ $METAREGEX;
'qr{ $x }' =~ $METAREGEX;

'qr{ @( ) }' =~ $METAREGEX;
'qr{ @| }' =~ $METAREGEX;
'qr{ ( @) }' =~ $METAREGEX;
'qr{ @_ }' =~ $METAREGEX;
'qr{ @x }' =~ $METAREGEX;

done_testing();

