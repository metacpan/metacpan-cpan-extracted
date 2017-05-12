#! perl
use strict;
use warnings;
use Test;
# Tests recommended in RT#60010 (adapted).
BEGIN { plan tests => 6, todo => [6] }

use SuffixTree;

my $str = "mississippi is long river";
my $tree = create_tree($str);
# print_tree($tree);

ok (find_substring($tree, "ssis") == 3);
ok (find_substring($tree, "pp") == 9);
ok (find_substring($tree, "ss") == 3);
ok (find_substring($tree, "ss") == 3);
ok ( ! find_substring($tree, "sss") ); # Not found: Error condition is -1.

# https://rt.cpan.org/Public/Bug/Display.html?id=11243
my $str2  = "x";
# this will redefine ST_ERROR and confuse suffex_tree.c:
my $tree2 = create_tree($str2);
my $query = "Missouri river";
ok ( ! find_substring($tree, $query) );

delete_tree($tree);
delete_tree($tree2);
