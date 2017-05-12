
use Test::More;

eval "require DBD::SQLite";
plan skip_all => "DBD::SQLite required for testing Tao::DBI" if $@;

plan tests => 11;

use_ok('Tao::DBI');

END {
    unlink 't/t.db' if -e 't/t.db';
}

my $dbh = Tao::DBI->connect( { dsn => 'dbi:SQLite:dbname=t/t.db' } );
ok( $dbh, 'defined $dbh' );

my $ans;

$ans = $dbh->do(
    qq{
  CREATE TABLE t (
    a integer,
    b integer,
    k integer
  )
}
);
ok( $ans, 'CREATE TABLE succeeded' );

my $sql = qq{INSERT INTO t (a, b, k) VALUES (:a, :b, :k)};
my $sth = $dbh->prepare($sql);
ok( $sth, 'prepare ok' );

$ans = $sth->execute( { a => 1, b => 1, k => 1 } );
ok( $ans, 'execute (1) ok' );
$ans = $sth->execute( { a => 2, b => 2, k => 2 } );
ok( $ans, 'execute (2) ok' );

$sql = qq{UPDATE t SET a = :a WHERE k = :k};
$sth = $dbh->prepare( { sql => $sql } );
ok( $sth, 'prepare($href) ok' );
$ans = $sth->execute( { a => 100, k => 1 } );
is( $ans, 1, 'exec UPDATE ok' );

eval { $sth = $dbh->prepare( { sql => undef } ); };
like( $@, qr/sql.*undef/, 'new({ sql => undef }) croaks' );

eval { $sth = $dbh->prepare(); };
like( $@, qr/sql.*undef/, 'new() w/o sql croaks' );

ok( $dbh->disconnect, "successful disconnection" );
