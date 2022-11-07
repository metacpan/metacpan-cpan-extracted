use Test::More;
use SQL::Load;

my $sql_load = SQL::Load->new('./t/sql');

my $users = $sql_load->load('users');

is(
    $users->name('insert'), 
    'INSERT INTO users (name, email, username, password) VALUES (?, ?, ?, ?);', 
    'Test get name (insert) by file users.sql'
);

is(
    $users->name('update'), 
    'UPDATE users SET name = ?, email = ?, username = ?, password = ? WHERE id = ?;', 
    'Test get name (update) by file users.sql'
);

is(
    $users->name('delete'), 
    'DELETE FROM users WHERE id = ?;', 
    'Test get name (delete) by file users.sql'
);

is(
    $users->name('find'), 
    'SELECT * FROM users WHERE id = ?;', 
    'Test get name (find) by file users.sql'
);

is(
    $users->name('find-all'), 
    'SELECT * FROM users ORDER BY id DESC;', 
    'Test get name (find-all) by file users.sql'
);

is(
    $users->name('find-by-email'), 
    'SELECT * FROM users WHERE email = ?;', 
    'Test get name (find-by-email) by file users.sql'
);

is(
    $users->name('find-by-username'), 
    'SELECT * FROM users WHERE username = ?;', 
    'Test get name (find-by-username) by file users.sql'
);

done_testing;
