#!perl

use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

use Role::Tiny;
use TableData::Test::Angka;

my $t = TableData::Test::Angka->new;
Role::Tiny->apply_roles_to_object($t, 'TableDataRole::Util::Random');

# minimal for now

subtest get_rand_row_arrayref => sub {
    my $res = $t->get_rand_row_arrayref;
    is(ref $res, 'ARRAY');
};

subtest get_rand_row_hashref => sub {
    my $res = $t->get_rand_row_hashref;
    is(ref $res, 'HASH');
};

subtest get_rand_rows_arrayref => sub {
    my $res = $t->get_rand_rows_arrayref(2);
    is(ref $res, 'ARRAY');
    is(scalar(@$res), 2);
    is(ref $res->[0], 'ARRAY');
};

subtest get_rand_rows_hashref => sub {
    my $res = $t->get_rand_rows_hashref(2);
    is(ref $res, 'ARRAY');
    is(scalar(@$res), 2);
    is(ref $res->[0], 'HASH');
};

done_testing;
