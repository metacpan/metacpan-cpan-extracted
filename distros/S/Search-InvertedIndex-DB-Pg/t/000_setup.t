use strict;
use Test::More tests => 1;

SKIP: {
    skip "Test database not configured", 1 unless -e "test.conf";

    require Config::Tiny;
    my $conf_ref = Config::Tiny->read( "test.conf" );
    my %conf = %{ $conf_ref->{_} };

    require DBI;
    my $dsn = "dbi:Pg:dbname=$conf{dbname}";
    $dsn .= ";host=$conf{dbhost}" if $conf{dbhost};
    $dsn .= ";port=$conf{dbport}" if $conf{dbport};
    my $dbh = DBI->connect( $dsn, $conf{dbuser}, $conf{dbpass} );

    my $sth = $dbh->prepare(
        "SELECT tablename FROM pg_tables WHERE tablename=?"
    );
    $sth->execute( "siindex" );
    my ($exists) = $sth->fetchrow_array;
    $sth->finish;

    $dbh->do( "DROP TABLE siindex" ) if $exists;
    $dbh->disconnect;

    pass "Test database cleared.";
}
