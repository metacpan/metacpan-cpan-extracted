use strict;
use warnings;

use T2();

my $t = T2->new(
    Basic => [qw/ok done_testing/],
    Compare => [qw/is like/],
);

$t->ok(1, "OO works fine");

$t->import(Class => [qw/can_ok/]);
$t->can_ok($t, qw/ok done_testing is like can_ok/);

ok $t(1, "Indirect object syntax (uhg)");

my $t2 = T2->new;
$t->ok($t != $t2, "Not the same instance");
$t->ok($$t ne $$t2, "Not the same stash (Implementation Detail)");
$t->ok(!$t2->can('ok'), "Not the same stash (Behavior)");

{
    no strict;

    BEGIN {
        my $t3 = T2->new;
        $t3->import('+strict');
    }

    $t->ok(
        eval '$xyz = 1' || 0,
        "OO import does not effect compiling scope",
    );
}

$t->done_testing;
