package TestDB;

use strict;
use warnings;

use base 'ObjectDB';

use TestDBH;

sub init_db {
    my $self = shift;

    return TestDBH->dbh;
}

1;
