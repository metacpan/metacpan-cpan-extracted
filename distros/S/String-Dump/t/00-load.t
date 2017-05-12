use strict;
use warnings;
use Test::More tests => 1;

BEGIN {
    use_ok 'String::Dump', qw(
        dump_hex
        dump_dec
        dump_oct
        dump_bin
        dump_names
        dump_codes
    );
}

diag "Testing String::Dump $String::Dump::VERSION, Perl $], $^X";
