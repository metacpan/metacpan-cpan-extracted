use strict;
use warnings;
use utf8;
use Test::More;
use t::Util;

compile_and_compare(
    "=begin pod\n=end pod\n",
    '(nop)'
);
compile_and_compare(
    "=begin pod\n=end pod\n1",
    '(statements (int 1))'
);
compile_and_compare(
    "=begin pod \n=end pod\n1",
    '(statements (int 1))'
);
compile_and_compare(
    "=begin pod \n=end pod \n1",
    '(statements (int 1))'
);
compile_and_compare(
    "=begin kwid \n=end kwid \n1",
    '(statements (int 1))'
);

done_testing;

