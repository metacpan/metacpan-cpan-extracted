#!perl

use strict;
use warnings;

use Test::More 0.98;

plan skip_all => "Unix only"
    if $^O =~ /MSWin32/;

use Proc::ChildError qw(explain_child_error);

like(explain_child_error(-1), qr/^failed to execute: \(-1\)/);

system "/tmp/ad5f9c00-bcad-d597-cce7-dc602c67546d";
like(explain_child_error(), qr/^failed to execute: \S.+ \(-1\)/);

like(explain_child_error(3), qr/^died with signal 3, without coredump$/);
like(explain_child_error(3|128), qr/^died with signal 3, with coredump$/);

like(explain_child_error(256), qr/^exited with code 1$/);

# option: prog
like(explain_child_error({prog=>"foo"}, 256), qr/^foo exited with code 1$/);

DONE_TESTING:
done_testing();
