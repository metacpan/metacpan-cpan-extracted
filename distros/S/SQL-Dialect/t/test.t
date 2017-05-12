#!/usr/bin/perl
use strict;
use warnings;

use Test::More;
use SQL::Dialect;

{
    package DBI::db;
    sub new {
        my $class = shift;
        return bless { Driver => { Name => shift } }, $class;
    }
}

my $dbh = DBI::db->new( 'mysql' );
my $dialect = SQL::Dialect->new( $dbh );

is( $dialect->limit(), 'xy', 'limit' );
is( $dialect->returning(), undef, 'returning' );
is( $dialect->sequences(), undef, 'sequences' );
is( $dialect->last_insert_id(), 1, 'last_insert_id' );
is( $dialect->last_insert_rowid(), undef, 'last_insert_rowid' );
is( $dialect->rownum(), undef, 'rownum' );
is( $dialect->quote_char(), '`', 'quote_char' );
is( $dialect->sep_char(), '.', 'sep_char' );

is( $dialect->supports('limit', 'last_insert_id'), 1, 'supports limit and last_insert_id' );
is( $dialect->supports('limit-offset', 'last_insert_id'), 0, 'does not support limit-offset' );
is( $dialect->supports('last_insert_id', 'limit-xy'), 1, 'supports limit-xy' );

done_testing;
