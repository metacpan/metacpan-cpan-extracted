
use Test::More;

eval "require DBD::SQLite";
plan skip_all => "DBD::SQLite required for testing Tao::DBI" if $@;

# this script is to make sure handling 'hh::mi' or 'hh:'||'mi"
# works alright

plan tests => 11;

use_ok('Tao::DBI');

END {
    unlink 't/t.db' if -e 't/t.db';
}

my $dbh = Tao::DBI->connect( { dsn => 'dbi:SQLite:dbname=t/t.db' } );
ok( $dbh, 'defined $dbh' );

{
    my $sql = qq{SELECT 'hh::mi'};
    my $sth = $dbh->prepare($sql);
    ok( $sth,            "prepare ok ('::' is escaped ':')" );
    ok( $sth->execute(), 'execute() ok' );
    is( $sth->fetchrow_array, 'hh:mi', 'fetchrow ok' );
    is( $sth->fetchrow_array, undef,   'fetchrow ok' );
}

{
    my $sql = qq{SELECT 'hh:'||'mi'};
    my $sth = $dbh->prepare($sql);
    ok( $sth,            "prepare ok ('::' is escaped ':')" );
    ok( $sth->execute(), 'execute() ok' );
    is( $sth->fetchrow_array, 'hh:mi', 'fetchrow ok' );
    is( $sth->fetchrow_array, undef,   'fetchrow ok' );
}

ok( $dbh->disconnect, "successful disconnection" );
