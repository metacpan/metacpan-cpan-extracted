use strict;
use lib qw(lib ../lib);
use Template::Test;
use Template::Plugin::TruncateByWord;

test_expect(\*DATA);


__DATA__

-- test --
[% USE TruncateByWord 'big5' -%]
[% 'abcdefg' | truncate_by_word(4) %]
-- expect --
abcd

-- test --
[% USE TruncateByWord 'big5' -%]
[% '國際編碼碼' | truncate_by_word(3) %]
-- expect --
國際編

-- test --
[% USE TruncateByWord 'big5' -%]
[% '國際a編碼b碼cdefg' | truncate_by_word(3) %]
-- expect --
國際a

-- test --
[% USE TruncateByWord 'big5' -%]
[% '國際a編碼b碼cdefg' | truncate_by_word %]
-- expect --
國際a編碼b碼cdefg

-- test --
[% USE TruncateByWord 'big5' -%]
[% '國際a編碼b碼cdefg' | truncate_by_word(5,'...') %]
-- expect --
國際a編碼...

-- test --
[% USE TruncateByWord 'big5' -%]
[% '國際a編碼b碼cdefg' | truncate_by_word(36,'...') %]
-- expect --
國際a編碼b碼cdefg

-- test --
[% USE TruncateByWord('big5', name='my_truncate') -%]
[% '國際a編碼b碼cdefg' | my_truncate(3) %]
-- expect --
國際a

-- test --
[% USE TruncateByWord 'big5' name='my_truncate' -%]
[% FILTER my_truncate(5,'..') -%]
國際a編碼b碼cdefg
[% END %]
-- expect --
國際a編碼..

-- test --
[% USE TruncateByWord enc='big5' name='my_truncate' -%]
[% FILTER my_truncate(5,'..') -%]
國際a編碼b碼cdefg
[% END %]
-- expect --
國際a編碼..
