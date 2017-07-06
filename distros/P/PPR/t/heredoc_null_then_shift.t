use warnings;
use strict;
use Test::More;

plan tests => 2;

use PPR;

my $code = <<'_EOT_';

<<<<<<A;1

42
A
_EOT_

ok $code =~ m{
    \A
    (?&PerlOWS)
    (?<statement> (?&PerlStatement)?)
    1\n
    \n
    42\n
    A\n
    \Z

    $PPR::GRAMMAR
}x => 'Matched';

is $+{statement}, "<<<<<<A;" => 'Matched correctly';

done_testing();
