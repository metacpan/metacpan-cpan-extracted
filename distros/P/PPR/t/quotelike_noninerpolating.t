use strict;
use warnings;

use Test::More;

BEGIN{
    BAIL_OUT "A bug in Perl 5.20 regex compilation prevents the use of PPR under that release"
        if $] > 5.020 && $] < 5.022;
}

plan tests => 8;

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

ok q{ qr'^([$@%*])(.+)$'               } =~ $METAREGEX  => 'qr';
ok q{  m'^([$@%*])(.+)$'               } =~ $METAREGEX  => 'm';
ok q{  s'^([$@%*])(.+)$' $_ 'e         } =~ $METAREGEX  => 's';
ok q{ qx' cmd   $-  $[  $etc  uncmd '  } =~ $METAREGEX  => 'qx';

$METAREGEX = qr{
    \A \s* (?&PerlQuotelike) \s* \Z

    (?(DEFINE)
        (?<PerlScalarAccessNoSpace>
            ((?&PerlStdScalarAccessNoSpace))
            (?{ pass "$^N should match a (?&PerlScalarAccessNoSpace)" })
        )

        (?<PerlArrayAccessNoSpace>
            ((?&PerlStdArrayAccessNoSpace))
            (?{ pass "$^N should match a (?&PerlArrayAccessNoSpace)" })
        )
    )

    $PPR::X::GRAMMAR
}xms;

ok q{ qq' quote $@  $_  $etc  unquote' } =~ $METAREGEX  => 'qq';

done_testing();


