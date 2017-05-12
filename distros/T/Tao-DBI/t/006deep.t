
use Test::More;

eval "require DBD::SQLite";
plan skip_all => "DBD::SQLite required for testing Tao::DBI" if $@;

eval "require YAML";
plan skip_all => "YAML required for this Tao::DBI test" if $@;

plan tests => 12;

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
    k integer,
    a integer,
    b integer,
    slurpy text
  )
}
);
ok( $ans, 'CREATE TABLE succeeded' );

my $sql  = qq{INSERT INTO t (k, a, b, slurpy) VALUES (:k, :a, :b, :more)};
my $meta = [ k => 'k', a => 'a', b => 'b', '*' => 'more:yaml' ];
my $sth  = $dbh->prepare( { sql => $sql, type => 'deep', meta => $meta } );
ok( $sth, 'prepare ok' );

$ans = $sth->execute( { a => 1, b => 1, k => 1, c => 'string', d => {} } );
ok( $ans, 'execute (1) ok' );

$sql = qq{SELECT k, a, b, slurpy more FROM t where k = :k };
$sth = $dbh->prepare( $sql, { type => 'deep', meta => $meta } );
ok( $sth, 'prepare SELECT ok' );
$ans = $sth->execute( { k => 1 } );
ok( $ans, 'exec SELECT ok' );
my $row = $sth->fetchrow_hashref();
is_deeply( $row, { a => 1, b => 1, k => 1, c => 'string', d => {} },
    'fetch ok' );

$ans = $sth->execute(1);
ok( $ans, 'exec SELECT (with single non-ref arg) ok' );
$row = $sth->fetchrow_hashref();
is_deeply( $row, { a => 1, b => 1, k => 1, c => 'string', d => {} },
    'fetch ok' );

ok( $sth->finish, "successful closing statement" );

ok( $dbh->disconnect, "successful disconnection" );

