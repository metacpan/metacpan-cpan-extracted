use strict;
use warnings;
use Test::More;

use Sub::Rate::NoMaxRate;

my ($r1, $r2);

my $sub = Sub::Rate::NoMaxRate->new;
$sub->add( 10 => sub { $r1++ });
$sub->add( 20 => sub { $r2++ });

my $func = $sub->generate;

my $loop_count = 0;
for (1 .. 100000) {
    $loop_count++;
    $func->();
}

is $loop_count, $r1 + $r2, 'loop count same as $r1 + $r2';

ok 2.0*0.95 <= $r2 / $r1 && $r2 / $r1 <= 2.0*1.05, '$r2/$1 about 20/10 ok';

$sub->clear;

eval { $sub->add(1000 => sub {}) };
ok !$@, 'no error ok (over default max_rate)';

done_testing;
