use lib '../lib';
use Test::More;
use DBI;
use SQLite_File;
use File::Spec;

my $dir = -d 't' ? 't' : '.';
my $db_name = File::Spec->catfile($dir,'test_a.db');
chmod 0666, $db_name;
my (@db,%db);
my $dbh = DBI->connect("dbi:SQLite:dbname=$db_name");
ok $dbh->ping, 'connect test_a.db';
my $rows = $dbh->selectall_arrayref('select * from hash');
is_deeply $rows, [[1, 'spam'],[2, 'eggs'],[3, 'sausage']], 'test.db ok before tie @db';
$dbh->disconnect;
{
  my @db;

  ok tie(@db,'SQLite_File',$db_name), 'array code';
  is_deeply \@db, [qw/spam eggs sausage/], 'tied array matches db';

}
$dbh = DBI->connect("dbi:SQLite:dbname=$db_name");
ok $dbh->ping, 'connect test_a.db (2)';
$rows = $dbh->selectall_arrayref('select * from hash');
is_deeply $rows, [[1, 'spam'],[2, 'eggs'],[3, 'sausage']], 'test_a.db ok after @db destroy';
$dbh->disconnect;

$db_name = File::Spec->catfile($dir,'test_h.db');
chmod 0666, $db_name;
$dbh = DBI->connect("dbi:SQLite:dbname=$db_name");
ok $dbh->ping, 'connect test_h.db';
$rows = $dbh->selectall_arrayref('select * from hash');
is_deeply $rows, [[1, 'spam', 1],[2, 'eggs', 2],[3, 'sausage', 3]], 'test.db ok before tie %db';
$dbh->disconnect;
{
  my %db;
  ok tie(%db,'SQLite_File',$db_name), 'hash code';
   is_deeply \%db, { 1 => 'spam', 2 => 'eggs', 3 => 'sausage' }, 'tied hash matches db';
}
$dbh = DBI->connect("dbi:SQLite:dbname=$db_name");
ok $dbh->ping(), 'connect test_h.db (2)';
$rows = $dbh->selectall_arrayref('select * from hash');
is_deeply $rows, [[1, 'spam', 1],[2, 'eggs', 2],[3, 'sausage', 3]], 'test.db ok after undef %db';
$dbh->disconnect;

done_testing;


