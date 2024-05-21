use Test::More;

use Rope::Handles::Number;

my $data = Rope::Handles::Number->new(1);

is($data->add(10), 11);

is($data->subtract(9), 2);

is($data->multiply(2), 4);

is($data->divide(2), 2);

done_testing();
