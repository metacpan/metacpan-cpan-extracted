use Test::More;

use Rope::Handles::Bool;
use Rope::Handles::Counter;

# Bool - clear method
my $bool = Rope::Handles::Bool->new(1);
is($bool->clear, 0);
is(${$bool}, 0);

# Bool - toggle from 0
$bool = Rope::Handles::Bool->new(0);
is($bool->toggle, 1);
is($bool->toggle, 0);

# Counter - reset
my $counter = Rope::Handles::Counter->new(50);
is($counter->reset, 0);
is(${$counter}, 0);

# Counter - clear (alias for reset)
$counter = Rope::Handles::Counter->new(100);
$counter->clear;
is(${$counter}, 0);

# Counter - increment with custom step
$counter = Rope::Handles::Counter->new(0);
is($counter->increment(5), 5);
is($counter->increment(3), 8);

# Counter - decrement with custom step
is($counter->decrement(2), 6);
is($counter->decrement(6), 0);

done_testing();
