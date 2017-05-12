use strict;
use utf8;
use Template::Test;

test_expect( \*DATA );

__END__
--test--
[% USE Lingua.JA.Regular.Unicode -%]
[% 'およよＡＢＣＤＥＦＧｂｆｅge１２３123オヨヨｵﾖﾖ' | hiragana2katakana %]
--expect--
オヨヨＡＢＣＤＥＦＧｂｆｅge１２３123オヨヨｵﾖﾖ
