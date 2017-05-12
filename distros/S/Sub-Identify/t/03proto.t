#!perl

use Test::More tests => 6;
use Sub::Identify ':all';
for my $f (qw(
    sub_name
    stash_name
    sub_fullname
    get_code_info
    get_code_location
    is_sub_constant
)) {
    is(prototype($f), '$', "Prototype of $f is \$")
}
