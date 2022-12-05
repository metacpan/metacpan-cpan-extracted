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

is(
    $sql_load->load('users#insert'), 
    'INSERT INTO users (name, email, username, password) VALUES (?, ?, ?, ?);', 
    'Test get name (insert) by file users.sql using method load with file#name'
);

is(
    $sql_load->load('users#update'), 
    'UPDATE users SET name = ?, email = ?, username = ?, password = ? WHERE id = ?;', 
    'Test get name (update) by file users.sql using method load with file#name'
);

is(
    $sql_load->load('users#delete'), 
    'DELETE FROM users WHERE id = ?;', 
    'Test get name (delete) by file users.sql using method load with file#name'
);

is(
    $sql_load->load('users#find'), 
    'SELECT * FROM users WHERE id = ?;', 
    'Test get name (find) by file users.sql using method load with file#name'
);

is(
    $sql_load->load('users#find-all'), 
    'SELECT * FROM users ORDER BY id DESC;', 
    'Test get name (find-all) by file users.sql using method load with file#name'
);

is(
    $sql_load->load('users#find-by-email'), 
    'SELECT * FROM users WHERE email = ?;', 
    'Test get name (find-by-email) by file users.sql using method load with file#name'
);

is(
    $sql_load->load('users#find-by-username'), 
    'SELECT * FROM users WHERE username = ?;', 
    'Test get name (find-by-username) by file users.sql using method load with file#name'
);

my $client_users = $sql_load->load('client/users');

is(
    $client_users->name('insert'), 
    'INSERT INTO users (name, email, username, password) VALUES (?, ?, ?, ?);', 
    'Test get name (insert) by file client/users.sql'
);

is(
    $client_users->name('update'), 
    'UPDATE users SET name = ?, email = ?, username = ?, password = ? WHERE id = ?;', 
    'Test get name (update) by file client/users.sql'
);

is(
    $client_users->name('delete'), 
    'DELETE FROM users WHERE id = ?;', 
    'Test get name (delete) by file client/users.sql'
);

is(
    $client_users->name('find'), 
    'SELECT * FROM users WHERE id = ?;', 
    'Test get name (find) by file client/users.sql'
);

is(
    $client_users->name('find-all'), 
    'SELECT * FROM users ORDER BY id DESC;', 
    'Test get name (find-all) by file client/users.sql'
);

is(
    $client_users->name('find-by-email'), 
    'SELECT * FROM users WHERE email = ?;', 
    'Test get name (find-by-email) by file client/users.sql'
);

is(
    $client_users->name('find-by-username'), 
    'SELECT * FROM users WHERE username = ?;', 
    'Test get name (find-by-username) by file client/users.sql'
);

is(
    $sql_load->load('client/users#insert'), 
    'INSERT INTO users (name, email, username, password) VALUES (?, ?, ?, ?);', 
    'Test get name (insert) by file client/users.sql using method load with file#name'
);

is(
    $sql_load->load('client/users#update'), 
    'UPDATE users SET name = ?, email = ?, username = ?, password = ? WHERE id = ?;', 
    'Test get name (update) by file client/users.sql using method load with file#name'
);

is(
    $sql_load->load('client/users#delete'), 
    'DELETE FROM users WHERE id = ?;', 
    'Test get name (delete) by file client/users.sql using method load with file#name'
);

is(
    $sql_load->load('client/users#find'), 
    'SELECT * FROM users WHERE id = ?;', 
    'Test get name (find) by file client/users.sql using method load with file#name'
);

is(
    $sql_load->load('client/users#find-all'), 
    'SELECT * FROM users ORDER BY id DESC;', 
    'Test get name (find-all) by file client/users.sql using method load with file#name'
);

is(
    $sql_load->load('client/users#find-by-email'), 
    'SELECT * FROM users WHERE email = ?;', 
    'Test get name (find-by-email) by file client/users.sql using method load with file#name'
);

is(
    $sql_load->load('client/users#find-by-username'), 
    'SELECT * FROM users WHERE username = ?;', 
    'Test get name (find-by-username) by file client/users.sql using method load with file#name'
);

done_testing;
