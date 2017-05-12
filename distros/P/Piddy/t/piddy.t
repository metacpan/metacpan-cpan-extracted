#!perl -T

use Test::More;

BEGIN {
    use_ok( 'Piddy' ) || print "Bail out!\n";
}

my $pid = Piddy->new({pid => $$}); # the test required this, no idea why yet

ok($pid->pid == $$, 'Pid returned a correct value') || diag $pid;

done_testing;
