use warnings;
use Test::More;

BEGIN{
    BAIL_OUT "A bug in Perl 5.20 regex compilation prevents the use of PPR under that release"
        if $] > 5.020 && $] < 5.022;
}

use re 'eval';

plan tests => 4;

use PPR;

my $MATCH_DOCUMENT = qr{ \A (?&PerlDocument) \z  $PPR::GRAMMAR }x;

my $code;
$code = <<'_EOT_';
<<A . <<A;
)
A
]]]
A
_EOT_

ok $code =~ $MATCH_DOCUMENT => 'AA';
ok $code =~ $MATCH_DOCUMENT => 'AA again';

$code = <<'_EOT_';
<<A . <<B;
))))
A
]]]]]]]]
B
_EOT_

ok $code =~ $MATCH_DOCUMENT => 'AB';


$code = <<'_EOT_';
<<A . <<A;
)
A
]]]
A
_EOT_

ok $code =~ $MATCH_DOCUMENT => 'AA yet again';

done_testing();
