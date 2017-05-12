use strict;
use lib qw(lib ../lib);
use Template::Test;
use Template::Plugin::TruncateByWord;

test_expect(\*DATA);


__DATA__

-- test --
[% USE TruncateByWord 'euc-kr' -%]
[% 'abcdefg' | truncate_by_word(4) %]
-- expect --
abcd

-- test --
[% USE TruncateByWord 'euc-kr' -%]
[% '±¤°íÇÁ·Î±×·¥' | truncate_by_word(3) %]
-- expect --
±¤°íÇÁ

-- test --
[% USE TruncateByWord 'euc-kr' -%]
[% '±¤°íaÇÁ·Îb±×·¥cdefg' | truncate_by_word(3) %]
-- expect --
±¤°ía

-- test --
[% USE TruncateByWord 'euc-kr' -%]
[% '±¤°íaÇÁ·Îb±×·¥cdefg' | truncate_by_word %]
-- expect --
±¤°íaÇÁ·Îb±×·¥cdefg

-- test --
[% USE TruncateByWord 'euc-kr' -%]
[% '±¤°íaÇÁ·Îb±×·¥cdefg' | truncate_by_word(5,'...') %]
-- expect --
±¤°íaÇÁ·Î...

-- test --
[% USE TruncateByWord 'euc-kr' -%]
[% '±¤°íaÇÁ·Îb±×·¥cdefg' | truncate_by_word(36,'...') %]
-- expect --
±¤°íaÇÁ·Îb±×·¥cdefg

-- test --
[% USE TruncateByWord('euc-kr', name='my_truncate') -%]
[% '±¤°íaÇÁ·Îb±×·¥cdefg' | my_truncate(3) %]
-- expect --
±¤°ía

-- test --
[% USE TruncateByWord 'euc-kr' name='my_truncate' -%]
[% FILTER my_truncate(5,'..') -%]
±¤°íaÇÁ·Îb±×·¥cdefg
[% END %]
-- expect --
±¤°íaÇÁ·Î..

-- test --
[% USE TruncateByWord enc='euc-kr' name='my_truncate' -%]
[% FILTER my_truncate(5,'..') -%]
±¤°íaÇÁ·Îb±×·¥cdefg
[% END %]
-- expect --
±¤°íaÇÁ·Î..
