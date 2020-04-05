# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl Return-Deep.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 6;
BEGIN { use_ok('Return::Deep') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my @Output;
my $Depth;

sub a {
    push @Output, "[a begin]";
    my @ret = eval {
        push @Output, "[a-eval begin]";
        my @ret = b();
        push @Output, "[a-eval end with", @ret, "]";
    };
    push @Output, "[a end with", @ret, "]";
}

sub b {
    push @Output, "[b begin]";
    my @ret = c();
    push @Output, "[b end with", @ret, "]";
}

sub c {
    push @Output, "[c begin]";
    my @ret = deep_ret($Depth, 3, 2, 'a');
    push @Output, "[c end with", @ret, "]";
}

sub test {
    $Depth = $_[0];

    @Output = "[test begin]";
    my @ret = a();
    push @Output, "[test end with", @ret, "]";

    is("@Output", $_[1], "test($_[0])");
}

test(0, '[test begin] [a begin] [a-eval begin] [b begin] [c begin] [c end with 3 2 a ] [b end with 10 ] [a-eval end with 13 ] [a end with 16 ] [test end with 19 ]');
test(1, '[test begin] [a begin] [a-eval begin] [b begin] [c begin] [b end with 3 2 a ] [a-eval end with 10 ] [a end with 13 ] [test end with 16 ]');
test(2, '[test begin] [a begin] [a-eval begin] [b begin] [c begin] [a-eval end with 3 2 a ] [a end with 10 ] [test end with 13 ]');
test(3, '[test begin] [a begin] [a-eval begin] [b begin] [c begin] [a end with 3 2 a ] [test end with 10 ]');
test(4, '[test begin] [a begin] [a-eval begin] [b begin] [c begin] [test end with 3 2 a ]');

