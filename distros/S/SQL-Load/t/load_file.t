use Test::More;
use SQL::Load;

my $sql_load = SQL::Load->new('./t/sql');

my $foo = $sql_load->load('foo');
is(ref($foo), 'SQL::Load::Method', 'Test if is a SQL::Load::Method ref');

is($foo->default, 'SELECT * FROM foo;', 'Test if default is same');
$foo->replace('foo' => 'baz');
is($foo->default, 'SELECT * FROM baz;', 'Test if default after replace');

my $read = $sql_load->load('Read');
is($read->name('find'), 'SELECT * FROM users WHERE id = ?;', 'Test name find by read');
is($read->name('FindAll'), 'SELECT * FROM users ORDER BY id;', 'Test name find-all by read');
is($read->name('find_by_name'), 'SELECT * FROM users WHERE name = ?;', 'Test name find-by-name by read');

is($read->next, 'SELECT * FROM users WHERE id = ?;', 'Test next find by read');
is($read->next, 'SELECT * FROM users ORDER BY id;', 'Test next find-all by read');
is($read->next, 'SELECT * FROM users WHERE name = ?;', 'Test next find-by-name by read');
isnt($read->next, 'undef', 'Test next with undef');

done_testing;
