use strict;
use utf8;
use Template::Test;

test_expect( \*DATA );

__END__
--test--
[% USE Lingua.JA.Regular.Unicode -%]
[% 'およよＡＢＣＤＥＦＧｂｆｅge１２３123オヨヨｵﾖﾖ' | katakana_h2z %]
--expect--
およよＡＢＣＤＥＦＧｂｆｅge１２３123オヨヨオヨヨ

--test--
[% USE Lingua.JA.Regular.Unicode -%]
[% 'ｶﾞ' | katakana_h2z %]
--expect--
ガ

--test--
[% USE Lingua.JA.Regular.Unicode -%]
[% '・･' | katakana_h2z %]
--expect--
・・
