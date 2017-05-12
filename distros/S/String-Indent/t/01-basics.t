#!perl

use 5.010;
use strict;
use warnings;

use Test::More 0.98;

use String::Indent qw(
                         indent
                          );

is(indent('xx', "1\n2 \n3 3\n\n"), "xx1\nxx2 \nxx3 3\nxx\n", "defaults");
is(indent('xx', "1\n\n2", {indent_blank_lines=>0}), "xx1\n\nxx2", "opt:indent_blank_lines=0");
is(indent('xx', "1\n\n2", {first_line_indent=>"x"}), "x1\nxx\nxx2", "opt:first_line_indent");
is(indent('xx', "1\n\n2", {subsequent_lines_indent=>"xxx"}), "xx1\nxxx\nxxx2", "opt:subsequent_lines_indent");
is(indent('xx', "1\n\n2", {first_line_indent=>"x", subsequent_lines_indent=>"xxx"}), "x1\nxxx\nxxx2", "opt:first_line_indent + opt:subsequent_lines_indent");

DONE_TESTING:
done_testing();
