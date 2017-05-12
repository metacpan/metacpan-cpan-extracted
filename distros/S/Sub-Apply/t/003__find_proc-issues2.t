package X;
use strict;
sub foo { 1 } 

package Y;
use strict;
our @ISA = "X";

package main;
use strict;
use warnings;
use Test::More tests => 3;
use Sub::Apply qw(apply);

{
    local $@;
    eval { apply('foo'); };
    ok $@, "main::foo doesn't exist";
}

{
    local $@;
    eval { apply('Y::foo'); };
    ok $@, "Y::foo doesn't exist";
}

{
    ok apply('X::foo'), "X::foo exists";
}
