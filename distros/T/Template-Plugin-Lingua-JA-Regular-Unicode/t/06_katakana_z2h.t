use strict;
use utf8;
use Template::Test;

test_expect( \*DATA );

__END__
--test--
[% USE Lingua.JA.Regular.Unicode -%]
[% 'およよＡＢＣＤＥＦＧｂｆｅge１２３123オヨヨｵﾖﾖ' | katakana_z2h %]
--expect--
およよＡＢＣＤＥＦＧｂｆｅge１２３123ｵﾖﾖｵﾖﾖ

--test--
[% USE Lingua.JA.Regular.Unicode -%]
[% 'ガ' | katakana_z2h %]
--expect--
ｶﾞ
