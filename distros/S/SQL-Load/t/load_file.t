use Test::More;
use SQL::Load;

my $sql_load = SQL::Load->new('./t/sql');

my $foo = $sql_load->load('foo');
is(ref($foo), 'SQL::Load::Method', 'Test if is a SQL::Load::Method ref');

is($foo->default, 'SELECT * FROM foo;', 'Test if default is same');
$foo->replace('foo' => 'baz');
is($foo->default, 'SELECT * FROM baz;', 'Test if default after replace');

$foo->reset;
is($foo->default, 'SELECT * FROM foo;', 'Test if default is same after reset');
$foo->replace('foo' => 'bar');
is($foo->default, 'SELECT * FROM bar;', 'Test if default again after replace');

my $read = $sql_load->load('Read');
is($read->name('find'), 'SELECT * FROM users WHERE id = ?;', 'Test name find by read');
is($read->name('FindAll'), 'SELECT * FROM users ORDER BY id;', 'Test name find-all by read');
is($read->name('find_by_name'), 'SELECT * FROM users WHERE name = ?;', 'Test name find-by-name by read');

is($read->next, 'SELECT * FROM users WHERE id = ?;', 'Test next find by read');
is($read->next, 'SELECT * FROM users ORDER BY id;', 'Test next find-all by read');
is($read->next, 'SELECT * FROM users WHERE name = ?;', 'Test next find-by-name by read');
isnt($read->next, 'undef', 'Test next with undef');

$read->replace('users', 'admins');

is($read->name('find'), 'SELECT * FROM admins WHERE id = ?;', 'Test name find by read after replace');
is($read->name('FindAll'), 'SELECT * FROM admins ORDER BY id;', 'Test name find-all by read after replace');
is($read->name('find_by_name'), 'SELECT * FROM admins WHERE name = ?;', 'Test name find-by-name by read after replace');

$read->reset;

is($read->name('find'), 'SELECT * FROM users WHERE id = ?;', 'Test name find by read after reset');
is($read->name('FindAll'), 'SELECT * FROM users ORDER BY id;', 'Test name find-all by read after reset');
is($read->name('find_by_name'), 'SELECT * FROM users WHERE name = ?;', 'Test name find-by-name by read after reset');

is($read->next, 'SELECT * FROM users WHERE id = ?;', 'Test next find by read after reset');
is($read->next, 'SELECT * FROM users ORDER BY id;', 'Test next find-all by read after reset');
is($read->next, 'SELECT * FROM users WHERE name = ?;', 'Test next find-by-name by read after reset');
isnt($read->next, 'undef', 'Test next with undef after reset');

done_testing;
