#!perl

use strict;
use warnings;

use SQL::Tokenizer qw(tokenize_sql);

use Test::More tests => 4;

my $sql_code = <<'SQL';
CREATE OR REPLACE FUNCTION getdatastore(integer, integer) RETURNS SETOF type_datastore
    AS $_$
        SELECT id,
               name
        FROM   data_store
        WHERE  storage_class = $1
               AND data_centre = $2
               AND active = true
        ORDER  BY name; 
    $_$
    LANGUAGE sql;
SQL

my @tokens = tokenize_sql($sql_code);

is( scalar( grep {/\$/} @tokens ), 4, 'Dollar token count correct' );    # old code would have 6 here
is( scalar( grep { $_ eq '$_$' } @tokens ), 2, '$_$ token count correct' );
is( scalar( grep { $_ eq '$1' } @tokens ),  1, '$1 token count correct' );
is( scalar( grep { $_ eq '$2' } @tokens ),  1, '$2 token count correct' );
