use strict;
use Test::More 0.98;

use_ok $_ for qw(
    Mojo::PgX::Cursor
    Mojo::PgX::Cursor::Cursor
    Mojo::PgX::Cursor::Database
    Mojo::PgX::Cursor::Results
);

done_testing;

