use strict;
use warnings;
use Test::More;

use SQL::Format;

my $f = SQL::Format->new;
subtest 'insert_multi no args' => sub {
    eval { $f->insert_multi };
    like $@, qr/Usage: \$sqlf->insert_multi\(/;
};

subtest 'insert_multi cols is not array' => sub {
    eval { $f->insert_multi(foo => {}) };
    like $@, qr/Usage: \$sqlf->insert_multi\(/;
};

subtest 'insert_multi values is not array' => sub {
    eval { $f->insert_multi(foo => [qw/bar baz/], {}) };
    like $@, qr/Usage: \$sqlf->insert_multi\(/;
};

subtest 'insert_multi_from_hash no args' => sub {
    eval { $f->insert_multi_from_hash };
    like $@, qr/Usage: \$sqlf->insert_multi_from_hash\(/;
};

subtest 'insert_multi_from_hash values is not array' => sub {
    eval { $f->insert_multi_from_hash(foo => {}) };
    like $@, qr/Usage: \$sqlf->insert_multi_from_hash\(/;
};

subtest 'insert_multi_from_hash values is not array in hash' => sub {
    eval { $f->insert_multi_from_hash(foo => [[]]) };
    like $@, qr/Usage: \$sqlf->insert_multi_from_hash\(/;
};

done_testing;
