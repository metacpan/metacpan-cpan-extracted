use Test::More;

use Rope::Handles::Number;

my $data = Rope::Handles::Number->new(10);

is($data->add(5), 15);
is($data->subtract(3), 12);
is($data->multiply(3), 36);
is($data->divide(6), 6);

# modulus
is($data->modulus(4), 2);

# absolute
$data = Rope::Handles::Number->new(-5);
is($data->absolute, 5);

$data = Rope::Handles::Number->new(7);
is($data->absolute, 7);

# increment with default step
$data = Rope::Handles::Number->new(10);
is($data->increment, 11);
is($data->increment, 12);

# increment with custom step
is($data->increment(5), 17);

# decrement with default step
is($data->decrement, 16);
is($data->decrement, 15);

# decrement with custom step
is($data->decrement(10), 5);

# clear
is($data->clear, 0);
is($data->add(1), 1);

done_testing();
