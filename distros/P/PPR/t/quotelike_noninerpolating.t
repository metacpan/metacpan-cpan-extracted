use strict;
use warnings;

use Test::More;

BEGIN{
    BAIL_OUT "A bug in Perl 5.20 regex compilation prevents the use of PPR under that release"
        if $] > 5.020 && $] < 5.022;
}

plan tests => 5;

use PPR::X;
use re 'eval';

my $METAREGEX = qr{
    \A \s* (?&PerlQuotelike) \s* \Z

    (?(DEFINE)
        (?<PerlScalarAccessNoSpace>
            ((?&PerlStdScalarAccessNoSpace))
            (?{ fail "$^N should not match a (?&PerlScalarAccessNoSpace)" })
        )

        (?<PerlArrayAccessNoSpace>
            ((?&PerlStdArrayAccessNoSpace))
            (?{ fail "$^N should not match a (?&PerlArrayAccessNoSpace)" })
        )
    )

    $PPR::X::GRAMMAR
}xms;

ok q{ qr'^([$@%*])(.+)$'               } =~ $METAREGEX;
ok q{  m'^([$@%*])(.+)$'               } =~ $METAREGEX;
ok q{  s'^([$@%*])(.+)$' $_ 'e         } =~ $METAREGEX;
ok q{ qq' quote $@  $_  $etc  unquote' } =~ $METAREGEX;
ok q{ qx' cmd   $-  $[  $etc  uncmd '  } =~ $METAREGEX;

done_testing();


