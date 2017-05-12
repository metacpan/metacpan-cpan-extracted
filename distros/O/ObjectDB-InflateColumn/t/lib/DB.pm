package DB;

use strict;
use warnings;

use base 'ObjectDB';

use FindBin;

our $dbh;

sub init_db {
    my $self = shift;

    return $dbh if $dbh;

    $dbh = DBI->connect_cached("dbi:SQLite:table.db");
    die $DBI::errorstr unless $dbh;

    $dbh->do("PRAGMA default_synchronous = OFF");
    $dbh->do("PRAGMA temp_store = MEMORY");

    return $dbh;
}

1;
