use strict;
use warnings;
use t::Util;
use Test::More;
use SQL::Format;

subtest '%t: undef' => sub {
    eval { sqlf 'SELECT foo FROM %t' };
    like $@, mk_errstr 1, '%t';
};

subtest '%w: undef' => sub {
    eval {
        sqlf 'SELECT %c FROM %t WHERE %w', (
            [qw/bar baz/], 'foo',
        );
    };
    like $@, mk_errstr 3, '%w';
};

subtest '%o: limit' => sub {
    eval {
        sqlf '%o', (
            { limit => 'foo' },
        );
    };
    like $@, qr/limit must be numeric specified/;
};

subtest '%o: offset' => sub {
    eval {
        sqlf '%o', (
            { limit => 10, offset => 'foo' },
        );
    };
    like $@, qr/offset must be numeric specified/;
};

done_testing;
