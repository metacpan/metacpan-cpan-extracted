#!perl -wT
use strict;
use warnings;
use Test::More;
use Schema::RackTables;


plan tests => 3;


my @versions = eval { Schema::RackTables->list_versions() };
is $@, "", '@versions = Schema::RackTables->list_versions()';
cmp_ok ~~@versions, ">=", 1, '@versions is not empty';
subtest '@versions contains version numbers' => sub {
    like $_, qr/^[0-9]+\.[0-9]+\.[0-9]+$/, "$_ is a RackTables version number"
        for @versions;
};

