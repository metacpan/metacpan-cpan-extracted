use strict;
use warnings;
use utf8;
use Test::More;
use Test::Requires 'DBD::SQLite';
use DBI;
use Teng::Schema::Loader;

{
    package My::DB;
    use parent qw/Teng/;
    __PACKAGE__->load_plugin('TextTable');
}

my $dbh = DBI->connect('dbi:SQLite::memory:', '', '', {RaiseError => 1, AutoCommit => 1});
$dbh->do(q{CREATE TABLE user (name, email)});
$dbh->do(q{INSERT INTO user (name, email) VALUES ('John', 'john@example.com'), ('Ben', 'ben@example.com')});
my $teng = Teng::Schema::Loader->load(dbh => $dbh, namespace => 'My::DB');

is($teng->draw_text_table('user', {}, {order_by => 'name'}), <<'...', 'simple');
.------+------------------.
| name | email            |
+------+------------------+
| Ben  | ben@example.com  |
| John | john@example.com |
'------+------------------'
...

is($teng->draw_text_table('user', {name => 'Ben'}, {order_by => 'name'}), <<'...', 'where');
.------+-----------------.
| name | email           |
+------+-----------------+
| Ben  | ben@example.com |
'------+-----------------'
...

is($teng->draw_text_table('user', {}, {order_by => 'name'}, ['name']), <<'...', 'specify cols');
.------.
| name |
+------+
| Ben  |
| John |
'------'
...

done_testing;

