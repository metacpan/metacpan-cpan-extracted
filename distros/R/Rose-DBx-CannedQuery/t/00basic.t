#!/usr/bin/env perl

# Basic testing that module loads and that a couple simple functions
# that don't require an actual db work

use Test::More tests => 4;

require_ok('Rose::DBx::CannedQuery');

ok(
    (
        not eval { Rose::DBx::CannedQuery->new( sql => 'SELECT nevermind' ) }
          and $@ =~
          /Need either Rose::DB object or information to construct one/
    ),
    'Required parameters'
);

is_deeply(
    Rose::DBx::CannedQuery->_default_rdb_params,
    {
        connect_options => {
            RaiseError => 1,
            PrintError => 0,
            AutoCommit => 1
        },
    },
    '_default_rdb_params'
);

my $broken_class = Rose::DBx::CannedQuery->new(
    sql        => 'SELECT * FROM test',
    rdb_class  => 'Not::Here',
    rdb_params => {}
);

ok( ( not eval { $broken_class->rdb } and $@ =~ /^Failed to load class/ ),
    'Nonexistent class error trapped' );

