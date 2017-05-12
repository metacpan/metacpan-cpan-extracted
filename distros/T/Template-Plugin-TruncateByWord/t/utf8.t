use strict;
use lib qw(lib ../lib);
use Template::Test;
use Template::Plugin::TruncateByWord;

test_expect(\*DATA);


__DATA__

-- test --
[% USE TruncateByWord -%]
[% 'abcdefg' | truncate_by_word(4) %]
-- expect --
abcd

-- test --
[% USE TruncateByWord -%]
[% 'あいうえお' | truncate_by_word(3) %]
-- expect --
あいう

-- test --
[% USE TruncateByWord -%]
[% 'あいaうえbおcdefg' | truncate_by_word(3) %]
-- expect --
あいa

-- test --
[% USE TruncateByWord -%]
[% 'あいaうえbおcdefg' | truncate_by_word %]
-- expect --
あいaうえbおcdefg

-- test --
[% USE TruncateByWord -%]
[% 'あいaうえbおcdefg' | truncate_by_word(5,'...') %]
-- expect --
あいaうえ...

-- test --
[% USE TruncateByWord -%]
[% 'あいaうえbおcdefg' | truncate_by_word(36,'...') %]
-- expect --
あいaうえbおcdefg

-- test --
[% USE TruncateByWord(name='my_truncate') -%]
[% 'あいaうえbおcdefg' | my_truncate(3) %]
-- expect --
あいa

-- test --
[% USE TruncateByWord name='my_truncate' -%]
[% FILTER my_truncate(5,'..') -%]
あいaうえbおcdefg
[% END %]
-- expect --
あいaうえ..

-- test --
[% USE TruncateByWord enc='utf8' name='my_truncate' -%]
[% FILTER my_truncate(5,'..') -%]
あいaうえbおcdefg
[% END %]
-- expect --
あいaうえ..
