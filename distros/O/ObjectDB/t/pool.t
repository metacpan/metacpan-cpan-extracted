use Test::Spec;
use Test::Fatal;

use lib 't/lib';

use TestDBH;
use ObjectDB::DBHPool;

describe 'pool' => sub {

    it 'return_handle' => sub {
        my $dbh = _build_pool()->dbh;

        ok($dbh);
    };

    it 'throw_on_invalid_dsn' => sub {
        my $e = exception { _build_pool(dsn => 'foo')->dbh };

        like($e, qr/Can't connect/);
    };

};

sub _build_pool {
    ObjectDB::DBHPool->new(dsn => 'dbi:SQLite:dbname=:memory:', @_);
}

runtests unless caller;
