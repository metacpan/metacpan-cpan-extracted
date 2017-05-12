
use Test::More;

eval "require DBD::SQLite";
plan skip_all => "DBD::SQLite required for testing Tao::DBI" if $@;

diag("DBD::SQLite VERSION: $DBD::SQLite::VERSION");

# this script test preparing statements with invalid SQL

plan tests => 6;

use_ok('Tao::DBI');

END {
    unlink 't/t.db' if -e 't/t.db';
}

my $dbh = Tao::DBI->connect(
    {
        dsn        => 'dbi:SQLite:dbname=t/t.db',
        PrintError => 0,                            # be quiet
        RaiseError => 0                             # don't die
    }
);
ok( $dbh, 'defined $dbh' );

{
    my $sql = qq{THIS IS NOT SQL};                  # bad input: not SQL at all
    my $sth = $dbh->prepare($sql);
    is( $sth, undef, 'prepare with bad SQL returns undef' );
}

{
    my $sql = qq{SELECT #};                         # with a strange character #
    my $sth = $dbh->prepare($sql);
    is( $sth, undef, 'prepare with bad SQL returns undef' );
}

{
    my $sql = qq{SELECT shoo};       # with an unknown field/column
    my $sth = $dbh->prepare($sql);
    is( $sth, undef, 'prepare with bad SQL returns undef' );
}

ok( $dbh->disconnect, "successful disconnection" );
