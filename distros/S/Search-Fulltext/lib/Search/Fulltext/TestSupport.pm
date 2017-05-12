package Search::Fulltext::TestSupport;
use strict;
use warnings;
use utf8;

use File::Temp;

sub make_tmp_file {
    File::Temp->new(
        TEMPLATE => 'Search-Fulltext-SQLite-XXXXXX',
        DIR      => File::Temp::tempdir(CLEANUP => 1),
        SUFFIX   => '.db',
        EXLOCK   => 0,
        UNLINK   => 1,
    );
}

1;
