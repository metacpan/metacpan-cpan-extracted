use Test::More;
use PGObject::Util::BulkLoad;
use DBI;

plan skip_all => 'Not set up for db tests' unless $ENV{DB_TESTING};
plan tests => 29;

# SETUP
my $dbh1 = DBI->connect('dbi:Pg:dbname=postgres', 'postgres');
$dbh1->do('CREATE DATABASE pgobject_test_db') if $dbh1;

my $dbh = DBI->connect('dbi:Pg:dbname=pgobject_test_db', 'postgres', undef, 
   {AutoCommit => 1});

$dbh->do('CREATE TABLE foo (foo text, bar int primary key, baz bigint)');
$dbh->do('CREATE TABLE foo2 ("fo""o""" text, "bar" int, "b""a""z" bigint)');

sub count_in_table {
    my ($name) = shift;
    my $sth = $dbh->prepare("SELECT COUNT(*) FROM $name");
    $sth->execute;
    my ($count) = $sth->fetchrow_array;
    return $count;
}

# TESTS

my $series1 = {
   insert_cols => [qw(foo bar baz)], 
   update_cols => [qw(foo baz)],
   key_cols    => ['bar'],
   table       => 'foo',
   dbh         => $dbh,
};

my $series2 = {
   insert_cols => [qw(foo bar baz)],
   update_cols => [qw(foo)],
   key_cols    => [qw(bar baz)],
   table       => 'foo',
   tempname    => 'tfoo',
   dbh         => $dbh,
};

my $series3 = {
   insert_cols => [qw(fo"o" bar b"a"z)],
   update_cols => [qw(fo"o" bar)],
   key_cols    => [qw(b"a"z)],
   table       => 'foo2',
   dbh         => $dbh,
};

my @mainobj = (
  { bar=> '422', baz => '123444', foo => 'foo',        },
  { bar=> '423', baz => '123444', foo => 'foo, bar',   },
  { bar=> '424', baz => '123446', foo => 'f,0,0,bar',  },
  { bar=> '425', baz => '123444', foo => 'foo2',       },
  { bar=> '426', baz => '123448', foo => 'foo3',       },
  { bar=> '427', baz => '123444', foo => 'foo4',       },
);

my @secondobj = (
  { bar=> '422', 'b"a"z' => '123444', 'fo"o"' => 'foo',        },
  { bar=> '423', 'b"a"z' => '123444', 'fo"o"' => 'foo, bar',   },
  { bar=> '424', 'b"a"z' => '123446', 'fo"o"' => 'f,0,0,bar',  },
  { bar=> '425', 'b"a"z' => '123444', 'fo"o"' => 'foo2',       },
  { bar=> '426', 'b"a"z' => '123448', 'fo"o"' => 'foo3',       },
  { bar=> '427',                      'fo"o"' => 'foo4',       },
);

ok(PGObject::Util::BulkLoad::copy($series1, @mainobj), 
   'Copied list of objects');

is(count_in_table('foo'), 6, '6 objects in table after first insert');

ok(!PGObject::Util::BulkLoad::copy($series1, @mainobj), 
   'Copying twice gives pkey violation');

is(count_in_table('foo'), 6, '6 objects in table after failed copy');

ok(PGObject::Util::BulkLoad::upsert($series1, @mainobj), 
'can upsert after copy');

is(count_in_table('foo'), 6, '6 objects in table after first upsert');

ok(!PGObject::Util::BulkLoad::copy($series1, @mainobj), 
   'Copying new series over old gives pkey violation');

is(count_in_table('foo'), 6, '6 objects in table after second failed copy');

my $stats;

ok($stats = PGObject::Util::BulkLoad::upsert(
             { %$series1, group_stats_by => ['foo']}, 
             @mainobj, 
             {foo => '123', bar => 111}), 
'can upsert after copy from previous routine');

for (@$stats) {
    if ($_->{keys}->{foo} eq '123') {
       is $_->{stats}->{inserts}, 1, "insert 1 for foo 123";
       is $_->{stats}->{updates}, 0, "update 0 for foo 123";
    } else {
       is $_->{stats}->{inserts}, 0, "insert 0 for foo $_->{keys}->{foo}";
       is $_->{stats}->{updates}, 1, "update 1 for foo $_->{keys}->{foo}";
    }
}

is(count_in_table('foo'), 7, '7 objects in table after second upsert');

is(count_in_table('foo2'), 0, 'foo2 empty before bulk load');

ok(PGObject::Util::BulkLoad::copy($series3, @secondobj),
   'escaped objects load properly');

is(count_in_table('foo2'), 6, '6 rows saved in copy to foo2');

ok(PGObject::Util::BulkLoad::upsert($series3, @secondobj, {'fo"o"' => '123', bar => 111, 'b"a"z' => 12222}), 
'can upsert after copy from previous routine');

is(count_in_table('foo2'), 7, '7 objects in foo2 after second upsert');


# CLEANUP
#
$dbh->disconnect;
$dbh1->do('DROP DATABASE pgobject_test_db');
