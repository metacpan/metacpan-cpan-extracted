#!perl

use strict;
use warnings;
use Test::More tests => 3;
use Sub::Current;

sub runcible {
    is(eval { ROUTINE() }, \&runcible, "runcible");
}
runcible();

sub omega {
    # eval("") is a special block context
    ok(!defined eval q{ ROUTINE() }, "omega");
}
omega();

sub master {
    is(do { ROUTINE() }, \&master, "master");
}
master();
