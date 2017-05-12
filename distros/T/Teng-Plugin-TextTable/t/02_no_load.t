use strict;
use warnings;
use utf8;
use Test::More;
use Test::Requires 'DBD::SQLite';
use DBI;
use Teng::Schema::Loader;

my $dbh = DBI->connect('dbi:SQLite::memory:', '', '', {RaiseError => 1, AutoCommit => 1});
$dbh->do(q{CREATE TABLE user (name, email)});
$dbh->do(q{INSERT INTO user (name, email) VALUES ('John', 'john@example.com'), ('Ben', 'ben@example.com')});
my $teng = Teng::Schema::Loader->load(dbh => $dbh, namespace => 'My::DB');

# You can use it without load plugins.
use Teng::Plugin::TextTable;
is($teng->Teng::Plugin::TextTable::draw_text_table('user', {}, {order_by => 'name'}), <<'...', 'simple');
.------+------------------.
| name | email            |
+------+------------------+
| Ben  | ben@example.com  |
| John | john@example.com |
'------+------------------'
...

done_testing;

