#!/usr/bin/env perl
use strict;
use warnings;
use 5.016;

use Test::More;
use FindBin;
require "$FindBin::Bin/test_setup.pl";

my $sluz = setup_sluz();

# -------------------------------------------------------------------
# Comment tests
# -------------------------------------------------------------------
sluz_test($sluz, '{* Comment *}'                       , '', 'Comment #1 - With text');
sluz_test($sluz, '{* ********* *}'                     , '', 'Comment #2 - ******');
sluz_test($sluz, '{**}'                                , '', 'Comment #3 - No whitespace');
sluz_test($sluz, '{*{$array|count}*}'                  , '', 'Comment #4 - Variable inside');
sluz_test($sluz, '{* {* nested *} *}'                  , '', 'Comment #5 - Nested');
sluz_test($sluz, '{* {* {* nested *} *} *}'            , '', 'Comment #6 - Triple Nested');
sluz_test($sluz, '{* {* {* {* nested *} *} *} *}'      , '', 'Comment #7 - 4-level nested');
sluz_test($sluz, '{* {* {* {* {* nested *} *} *} *} *}', '', 'Comment #8 - 5-level nested (max depth)');

# -------------------------------------------------------------------
# Comment-on-its-own-line tests: comment should not contribute a \n
# -------------------------------------------------------------------
sluz_test($sluz, "before\n{* x *}\nafter", "before\nafter",
    'Comment #9 - Own line does not add blank line');
sluz_test($sluz, "before\n\n{* x *}\n\nafter", "before\n\n\nafter",
    'Comment #10 - Own line between two blank lines');
sluz_test($sluz, "{* x *}\nafter", "after",
    'Comment #11 - First line is comment');
sluz_test($sluz, "before\n{* x *}", "before\n",
    'Comment #12 - Last line is comment');
sluz_test($sluz, "a\n{* x *}\n{* y *}\nb", "a\nb",
    'Comment #13 - Two consecutive comment-only lines');
sluz_test($sluz, "{* a *}\n{* b *}\n", "",
    'Comment #14 - Two consecutive comments with trailing newline');

done_testing();
