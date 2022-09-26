#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dumper;
BEGIN { $Data::Dumper::Useqq = 1; }

use Test::More;
use Test::FailWarnings;
use Test::Deep;

use Protocol::Dqlite;

my $dqlite = Protocol::Dqlite->new();

my @msgs = $dqlite->feed(
"\1\0\0\0\2\0\0\0\230:\0\0\0\0\0\0\5\0\0\0\3\0\0\0\1\0\0\0\0\0\0\0\276U1\214\205q\301-127.0.0.1:9001\0\0\0\0\0\0\0\0\0\0\1\0\0\0\4\0\0\0\0\0\0\0\377\377\0\0\36\0\0\0\a\0\0\0\5\0\0\0\0\0\0\0type\0\0\0\0name\0\0\0\0tbl_name\0\0\0\0\0\0\0\0rootpage\0\0\0\0\0\0\0\0sql\0\0\0\0\0003\23\3\0\0\0\0\0table\0\0\0model\0\0\0model\0\0\0\2\0\0\0\0\0\0\0CREATE TABLE model (key TEXT, value TEXT, UNIQUE(key))\0\0003\23\5\0\0\0\0\0index\0\0\0sqlite_autoindex_model_1\0\0\0\0\0\0\0\0model\0\0\0\3\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\377\377\377\377\377\377\377\377\a\0\0\0\a\0\0\0\2\0\0\0\0\0\0\0?\0\0\0\0\0\0\00023 + ?\0\0\22\0\0\0\0\0\0\0\\\217\302\365(\\\35\@ \0\0\0\0\0\0\0\377\377\377\377\377\377\377\377");

push @msgs, $dqlite->feed("\5\0\0\0\a\0\0\0\1\0\0\0\0\0\0\0?\0\0\0\0\0\0\0\3\0\0\0\0\0\0\0\303\251p\303\251e\0\0\377\377\377\377\377\377\377\377");

cmp_deeply(
    \@msgs,
    [
        all( Isa('Protocol::Dqlite::Response::WELCOME'), ),
        all(
            Isa('Protocol::Dqlite::Response::SERVERS'),
            methods(
                count => 1,
                [ id      => 0 ] => 3297041220608546238,
                [ address => 0 ] => '127.0.0.1:9001',
                [ role    => 0 ] => Protocol::Dqlite::ROLE_VOTER,
            ),
        ),
        all(
            Isa('Protocol::Dqlite::Response::DB'),
            methods(
                id => 0,
            ),
        ),
        all(
            Isa('Protocol::Dqlite::Response::ROWS'),
            methods(
                is_final   => bool(1),
                rows_count => 2,
            ),
            listmethods(
                [ row_types => 0 ] => [
                    Protocol::Dqlite::TUPLE_STRING,
                    Protocol::Dqlite::TUPLE_STRING,
                    Protocol::Dqlite::TUPLE_STRING,
                    Protocol::Dqlite::TUPLE_INT64,
                    Protocol::Dqlite::TUPLE_STRING,
                ],
                [ row_data => 0 ] => [
                    "table", "model", "model", 2,
                    "CREATE TABLE model (key TEXT, value TEXT, UNIQUE(key))",
                ],
                column_names =>
                  [ "type", "name", "tbl_name", "rootpage", "sql", ],
            ),
        ),
        all(
            Isa('Protocol::Dqlite::Response::ROWS'),
            methods(
                is_final   => bool(1),
                rows_count => 1,
            ),
            listmethods(
                column_names => [ "?", "23 + ?" ],
            ),
        ),
	all(
            Isa('Protocol::Dqlite::Response::ROWS'),
            methods(
                is_final   => bool(1),
                rows_count => 1,
            ),
            listmethods(
                column_names => [ "?" ],
		[ row_types => 0 ] => [ Protocol::Dqlite::TUPLE_STRING ],
		[ row_data => 0 ] => ["\xe9p\xe9e"],
            ),
        ),
    ],
    'messages as expected',
) or diag explain \@msgs;

done_testing;

1;
