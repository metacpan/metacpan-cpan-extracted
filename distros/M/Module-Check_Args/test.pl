# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

use strict;
use vars qw($loaded);
use Test;
BEGIN { plan tests => 10 }
END {print "not ok 1\n" unless $loaded;}
use Module::Check_Args;
$loaded = 1;
ok($loaded);

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):
sub sub1 {
    exact_argcount 3;
}

sub sub2 {
    atleast_argcount 2;
}

sub sub3 {
    atmost_argcount 2;
}

sub sub4 {
    range_argcount 1, 4;
}

{
    eval { sub1(2, 3); };
    ok($@ =~ /wrong number of arguments/);
    eval { sub1(2, 3, 4); };
    ok(!$@);
    eval { sub2(1); };
    ok($@ =~ /not enough arguments/);
    eval { sub2(1, 2, 3); };
    ok(!$@);
    eval { sub3(3, 4, 5); };
    ok($@ =~ /too many arguments/);
    eval { sub3(1); };
    ok(!$@);
    eval { sub4(); };
    ok($@ =~ /wrong number of arguments/);
    eval { sub4(2, 3, 4); };
    ok(!$@);
    eval { sub4(2, 3, 4, 5, 6); };
    ok($@ =~ /wrong number of arguments/);
}
