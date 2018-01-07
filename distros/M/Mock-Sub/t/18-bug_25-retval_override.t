use strict;
use warnings;

use Test::More;
use Mock::Sub;

package Testing; {
    sub one {
        return 1;
    }
    sub two {
        return 2;
    }
    sub three {
        return 3;
    }
}

package main;

my $m = Mock::Sub->new;

my $one = $m->mock('Testing::one', return_value => "ok");
my $two = $m->mock('Testing::two');
my $three = $m->mock('Testing::three');

is Testing::one, "ok", "first sub retval set ok";
is Testing::two, undef, "retval set in sub 1 doesn't override sub 2";
is Testing::three, undef, "retval set in sub 1 doesn't override sub 3";

done_testing();

