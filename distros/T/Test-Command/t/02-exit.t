#!perl

use Test::Command tests => 8;

use Test::More;

## determine whether we can run perl or not

system qq($^X -e 1) and BAIL_OUT('error calling perl via system');

is( exit_value(qq($^X -e "1")),          0, "exit_value 0");
is( exit_value(qq($^X -e "exit 1")),     1, "exit_value 1");

exit_is_num(qq($^X -e "exit 1"), 1);
exit_is_num(qq($^X -e "exit 255"), 255);
exit_is_defined(qq($^X -e "exit 255"));

SKIP:
   {
   skip("not sure about Win32 signal support", 1) if $^O eq 'MSWin32';
   exit_is_undef([$^X,  '-e', 'kill q(TERM), $$']);
   }

exit_isnt_num(qq($^X -e 1), 2);

exit_cmp_ok(qq($^X -e "exit 1"), '<', 2);
