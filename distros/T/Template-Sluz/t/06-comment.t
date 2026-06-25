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

done_testing();
