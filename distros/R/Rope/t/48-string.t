use Test::More;

use Rope::Handles::String;

my $data = Rope::Handles::String->new('a');

for (1 .. 20) {
	is($data->increment, "a$_");
}

for (reverse 1 .. 19) {
	is($data->decrement, "a$_");
}

is($data->decrement, 'a');

is($data->append('bc'), 'abc');

is($data->prepend('bc'), 'bcabc');

is($data->replace('bc(\w)bc'), 'a');

done_testing();
