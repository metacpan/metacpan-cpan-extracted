#!/usr/local/bin/perl

use Test::More qw( no_plan );

BEGIN { use_ok( 'Regexp::Common::Markdown' ) || BAIL_OUT( "Unable to load Regexp::Common::Markdown" ); }

use lib './lib';
use Regexp::Common qw( Markdown );
require( "./t/functions.pl" ) || BAIL_OUT( "Unable to find library \"functions.pl\"." );

my $tests = 
[
    {
        list_after => "",
        list_all => " * ABC\n *\n * DEF\n",
        list_content => "ABC\n *\n * DEF\n",
        list_prefix => " * ",
        list_type_any => "*",
        list_type_unordered_star => "*",
        name => "Empty items",
        test => <<EOT,
 * ABC
 *
 * DEF
EOT
    },
    {
        list_after        => "",
        list_all          => "1. ONE\n2.\n3. THREE\n",
        list_content      => "ONE\n2.\n3. THREE\n",
        list_prefix       => "1. ",
        list_type_any     => "1.",
        list_type_ordered => "1.",
        name => "Empty items",
        test => <<EOT,
1. ONE
2.
3. THREE
EOT
    },
    {
        list_after => "",
        list_all => "- HIJ\n-\n- KLM\n",
        list_content => "HIJ\n-\n- KLM\n",
        list_prefix => "- ",
        list_type_any => "-",
        list_type_unordered_minus => "-",
        name => "Empty items",
        test => <<EOT,
- HIJ
-
- KLM
EOT
    },
    {
        list_after => "",
        list_all => " * NOP\n * QRS\n *\n",
        list_content => "NOP\n * QRS\n *\n",
        list_prefix => " * ",
        list_type_any => "*",
        list_type_unordered_star => "*",
        name => "Empty items",
        test => <<EOT,
 * NOP
 * QRS
 *
EOT
    },
    {
        list_after        => "",
        list_all          => "1. FOUR\n2. FIVE\n3.\n",
        list_content      => "FOUR\n2. FIVE\n3.\n",
        list_prefix       => "1. ",
        list_type_any     => "1.",
        list_type_ordered => "1.",
        name => "Empty items",
        test => <<EOT,
1. FOUR
2. FIVE
3.
EOT
    },
    {
        list_after => "",
        list_all => "- TUV\n- WXY\n-\n",
        list_content => "TUV\n- WXY\n-\n",
        list_prefix => "- ",
        list_type_any => "-",
        list_type_unordered_minus => "-",
        name => "Empty items",
        test => <<EOT,
- TUV
- WXY
-
EOT
    },
    {
        list_after => "",
        list_all => "* test1\n+ test2\n- test3\n\n1. test4\n2. test5\n\n* test6\n+ test7\n- test8\n\n1. test9\n2. test10\n",
        list_content => "test1\n+ test2\n- test3\n\n1. test4\n2. test5\n\n* test6\n+ test7\n- test8\n\n1. test9\n2. test10\n",
        list_prefix => "* ",
        list_type_any => "*",
        list_type_unordered_star => "*",
        name => "List mixed ordered and unordered",
        test => <<EOT,
* test1
+ test2
- test3

1. test4
2. test5

* test6
+ test7
- test8

1. test9
2. test10
EOT
    },
    {
        list_after => "",
        list_all => "* ABC\n* DEF\n\n1. ONE\n2. TWO\n\n* GHI\n* JKL\n1. JKL-1\n2. JKL-2\n",
        list_content => "ABC\n* DEF\n\n1. ONE\n2. TWO\n\n* GHI\n* JKL\n1. JKL-1\n2. JKL-2\n",
        list_prefix => "* ",
        list_type_any => "*",
        list_type_unordered_star => "*",
        name => "List adjacent",
        test => <<EOT,
* ABC
* DEF

1. ONE
2. TWO

* GHI
* JKL
1. JKL-1
2. JKL-2
EOT
    },
    {
        list_after => "",
        list_all => "* ABC\n* DEF\n\n1. ONE\n2. TWO\n\n* GHI\n* JKL\n    1. JKL-1\n    2. JKL-2\n",
        list_content => "ABC\n* DEF\n\n1. ONE\n2. TWO\n\n* GHI\n* JKL\n    1. JKL-1\n    2. JKL-2\n",
        list_prefix => "* ",
        list_type_any => "*",
        list_type_unordered_star => "*",
        name => "List adjacent",
        test => <<EOT,
* ABC
* DEF

1. ONE
2. TWO

* GHI
* JKL
    1. JKL-1
    2. JKL-2
EOT
    },
];

run_tests( $tests,
{
    debug => 1,
    re => $RE{Markdown}{List},
    type => 'List',
});
