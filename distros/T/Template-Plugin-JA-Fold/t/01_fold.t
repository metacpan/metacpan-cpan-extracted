use strict;
use utf8;
use Template::Test;

test_expect(\*DATA, { ENCODING => 'utf-8' });

__END__
--test--
[% USE JA::Fold -%]
[% FILTER fold(10) -%]
abcdefghijklmnopqrstuvwxyz
[% END -%]
--expect--
abcdefghij
klmnopqrst
uvwxyz
--test--
[% USE JA::Fold -%]
[% FILTER fold(10,'full-width') -%]
abcdefghijklmnopqrstuvwxyz
[% END -%]
--expect--
abcdefghijklmnopqrst
uvwxyz
--test--
[% USE JA::Fold -%]
[% FILTER fold(10,'full-width') -%]
あいうえおかきくけこさしすせそたちつてとなにぬねの
[% END -%]
--expect--
あいうえおかきくけこ
さしすせそたちつてと
なにぬねの
--test--
[% USE JA::Fold -%]
[% FILTER fold(5,'full-width') -%]
abcdefあいうえおかきくけこghijklmn
[% END -%]
--expect--
abcdefあい
うえおかき
くけこghij
klmn