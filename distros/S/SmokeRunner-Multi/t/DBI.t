use strict;
use warnings;

use Test::More tests => 2;

use SmokeRunner::Multi::DBI;

use lib 't/lib';
use SmokeRunner::Multi::Test;


test_setup();

my $dbh = SmokeRunner::Multi::DBI::handle();
ok( $dbh, 'got a handle back from handle()' );
ok( ( grep { $_ =~ /TestSet/ } $dbh->tables() ),
    'database has been instantiated' );
