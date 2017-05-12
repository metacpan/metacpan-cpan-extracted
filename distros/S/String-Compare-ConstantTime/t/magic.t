use String::Compare::ConstantTime qw/equals/;

use strict;

use Test::More tests => 2;

ok equals substr( "asdfg", 0, 4 ), "asdf";
ok equals "asdf", substr( "asdfg", 0, 4 );
