#!perl

use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

use DBI;
use File::Temp qw(tempfile);
use Role::Tiny;
use TableData::DBI;

my ($tempfh, $tempfile) = tempfile();
my $dbh = DBI->connect("dbi:SQLite:dbname=$tempfile", undef, undef, {RaiseError=>1});
$dbh->do("CREATE TABLE t (i INT PRIMARY KEY, t TEXT)");
$dbh->do("INSERT INTO t VALUES (1, 'one')");
$dbh->do("INSERT INTO t VALUES (2, 'two')");
$dbh->do("INSERT INTO t VALUES (3, 'three')");

# XXX test accept dsn, user, password instead of dbh
# XXX test accept sth & row_count_sth
# XXX test accept dbh, query, row_count_query

my $t = TableData::DBI->new(dbh=>$dbh, table=>'t');
Role::Tiny->apply_roles_to_object($t, 'TableDataRole::Util::CSV');

is($t->as_csv, <<_);
i,t
1,one
2,two
3,three
_

is($t->get_column_count, 2);
is_deeply([$t->get_column_names], [qw/i t/]);
$t->reset_iterator;
is_deeply($t->get_next_item, [qw/1 one/]);
is_deeply($t->get_next_row_hashref , {i=>2, t=>'two'});
$t->reset_iterator;
is_deeply($t->get_next_row_arrayref , [1, 'one']);
is($t->get_row_count, 3);

done_testing;
