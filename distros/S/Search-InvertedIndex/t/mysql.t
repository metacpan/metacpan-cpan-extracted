use strict;
use Test::More;

my $dsn    = $ENV{SII_TESTDB_DSN};
my $dbname = $ENV{SII_TESTDB_NAME};
my $dbuser = $ENV{SII_TESTDB_USER} || "";
my $dbpass = $ENV{SII_TESTDB_PASS} || "";
my $dbhost = $ENV{SII_TESTDB_HOST} || "";

unless ( ($dsn or $dbname) ) {
    plan skip_all => "Set ENV variables as described in README to enable MySQL tests";
} else {
    plan tests => 5;
    use_ok( "Search::InvertedIndex::DB::Mysql" );

    # Explicitly drop Search::InvertedIndex table to test creation from scratch
    unless ( $dsn ) {
        $dsn = "dbi:mysql:database=$dbname";
        $dsn .= ";host=$dbhost" if $dbhost;
    }
    my $dbh = DBI->connect( $dsn, $dbuser, $dbpass );
    $dbh->do( "DROP TABLE IF EXISTS siindex" ) or die "Can't drop table";
    $dbh->disconnect;

    # Test instantiation.
    my $indexdb = Search::InvertedIndex::DB::Mysql->new(
        -db_name    => $dbname,
        -hostname   => $dbhost,
        -username   => $dbuser,
        -password   => $dbpass,
        -table_name => "siindex",
        -lock_mode  => "EX",
    );
    isa_ok( $indexdb, "Search::InvertedIndex::DB::Mysql" );

    # Test that we can open a db when the table doesn't already exist.
    eval { $indexdb->open; };
    is( $@, "", "->open succeeds when table doesn't already exist" );

    # Test that we can open a db when the table *does* already exist.
    eval { $indexdb->open; };
    is( $@, "", "->open succeeds when table already exists" );

    # Test that opening a db doesn't warn.
    eval { local $SIG{__WARN__} = sub { die $_[0] }; $indexdb->open; };
    is ( $@, "", "->open doesn't throw warning" );

}
