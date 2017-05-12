use strict;
use utf8;
use Template::Test;

test_expect( \*DATA );

__END__
--test--
[% USE Lingua.JA.Regular.Unicode -%]
[% 'およよＡＢＣＤＥＦＧｂｆｅge１２３123オヨヨｵﾖﾖ' | katakana2hiragana %]
--expect--
およよＡＢＣＤＥＦＧｂｆｅge１２３123およよおよよ

--test--
[% USE Lingua.JA.Regular.Unicode -%]
[% FILTER katakana2hiragana -%]
およよＡＢＣＤＥＦＧｂｆｅge１２３123オヨヨｵﾖﾖ
[% END -%]
--expect--
およよＡＢＣＤＥＦＧｂｆｅge１２３123およよおよよ
