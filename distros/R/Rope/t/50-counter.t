use Test::More;

use Rope::Handles::Counter;

my $data = Rope::Handles::Counter->new(0);

for (1 .. 20) {
	is($data->increment, $_);
}

for (reverse 1 .. 19) {
	is($data->decrement, $_);
}

done_testing();
