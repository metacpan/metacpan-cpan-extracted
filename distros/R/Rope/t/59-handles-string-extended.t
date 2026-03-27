use Test::More;

use Rope::Handles::String;

# match
my $data = Rope::Handles::String->new('hello world');
ok($data->match('hello'));
ok($data->match('wor'));
ok(!$data->match('xyz'));

# length
is($data->length, 11);

# chop
$data = Rope::Handles::String->new('abc');
is($data->chop, 'c');
is($data->length, 2);

# chomp
$data = Rope::Handles::String->new("hello\n");
is($data->chomp, 1);
is($data->length, 5);

# clear
$data = Rope::Handles::String->new('something');
is($data->clear, '');
is($data->length, 0);

# substr - two args (from offset to end)
$data = Rope::Handles::String->new('hello world');
is($data->substr(6), 'world');

# substr - three args (offset + length)
$data = Rope::Handles::String->new('hello world');
is($data->substr(0, 5), 'hello');

# substr - four args (offset, length, replacement)
$data = Rope::Handles::String->new('hello world');
$data->substr(0, 5, 'goodbye');
is(${$data}, 'goodbye world');

# replace with replacement string
$data = Rope::Handles::String->new('foo bar');
is($data->replace('foo', 'baz'), 'baz bar');

# replace with callback
$data = Rope::Handles::String->new('hello');
is($data->replace('hello', sub { 'goodbye' }), 'goodbye');

# append and prepend chaining
$data = Rope::Handles::String->new('mid');
is($data->append('dle'), 'middle');
is($data->prepend('the '), 'the middle');

done_testing();
