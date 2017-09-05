use strict;
use warnings;
use lib 't/lib';

use Test::More;
use Test::Fatal;

use TestDBH;

use_ok 'ObjectDB::DBHPool';

subtest 'returns handle' => sub {
    my $dbh = _build_pool()->dbh;

    ok($dbh);
};

subtest 'throws on invalid dsn' => sub {
    my $e = exception { _build_pool(dsn => 'foo')->dbh };

    like($e, qr/Can't connect/);
};

done_testing;

sub _build_pool {
    ObjectDB::DBHPool->new(dsn => $ENV{TEST_OBJECTDB_DBH} || 'dbi:SQLite:dbname=:memory:', @_);
}
