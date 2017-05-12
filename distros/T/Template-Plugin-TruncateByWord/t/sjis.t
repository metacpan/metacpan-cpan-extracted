use strict;
use lib qw(lib ../lib);
use Template::Test;
use Template::Plugin::TruncateByWord;

test_expect(\*DATA);


__DATA__

-- test --
[% USE TruncateByWord 'shiftjis' -%]
[% 'abcdefg' | truncate_by_word(4) %]
-- expect --
abcd

-- test --
[% USE TruncateByWord 'shiftjis' -%]
[% '‚ ‚¢‚¤‚¦‚¨' | truncate_by_word(3) %]
-- expect --
‚ ‚¢‚¤

-- test --
[% USE TruncateByWord 'shiftjis' -%]
[% '‚ ‚¢a‚¤‚¦b‚¨cdefg' | truncate_by_word(3) %]
-- expect --
‚ ‚¢a

-- test --
[% USE TruncateByWord 'shiftjis' -%]
[% '‚ ‚¢a‚¤‚¦b‚¨cdefg' | truncate_by_word %]
-- expect --
‚ ‚¢a‚¤‚¦b‚¨cdefg

-- test --
[% USE TruncateByWord 'shiftjis' -%]
[% '‚ ‚¢a‚¤‚¦b‚¨cdefg' | truncate_by_word(5,'...') %]
-- expect --
‚ ‚¢a‚¤‚¦...

-- test --
[% USE TruncateByWord 'shiftjis' -%]
[% '‚ ‚¢a‚¤‚¦b‚¨cdefg' | truncate_by_word(36,'...') %]
-- expect --
‚ ‚¢a‚¤‚¦b‚¨cdefg

-- test --
[% USE TruncateByWord('shiftjis', name='my_truncate') -%]
[% '‚ ‚¢a‚¤‚¦b‚¨cdefg' | my_truncate(3) %]
-- expect --
‚ ‚¢a

-- test --
[% USE TruncateByWord 'shiftjis' name='my_truncate' -%]
[% FILTER my_truncate(5,'..') -%]
‚ ‚¢a‚¤‚¦b‚¨cdefg
[% END %]
-- expect --
‚ ‚¢a‚¤‚¦..

-- test --
[% USE TruncateByWord enc='shiftjis' name='my_truncate' -%]
[% FILTER my_truncate(5,'..') -%]
‚ ‚¢a‚¤‚¦b‚¨cdefg
[% END %]
-- expect --
‚ ‚¢a‚¤‚¦..
