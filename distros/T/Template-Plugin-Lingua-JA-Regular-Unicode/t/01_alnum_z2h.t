use strict;
use utf8;
use Template::Test;

test_expect( \*DATA );

__END__
--test--
[% USE Lingua.JA.Regular.Unicode -%]
[% 'およよＡＢＣＤＥＦＧｂｆｅge１２３123' | alnum_z2h %]
--expect--
およよABCDEFGbfege123123
