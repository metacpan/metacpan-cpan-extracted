#!perl

use strict;
use warnings;

use SQL::Tokenizer qw(tokenize_sql);

use Test::More tests => 1;

my $sql_code = <<'SQL';
CREATE OR REPLACE FUNCTION fib (
    fib_for integer
) RETURNS integer AS $$
BEGIN
    IF fib_for < 2 THEN
        RETURN fib_for;
    END IF;
    RETURN fib(fib_for - 2) + fib(fib_for - 1);
END;
$$ LANGUAGE plpgsql;
SQL

my @tokens = tokenize_sql($sql_code);

my @dollar_tokens = grep { /\$/ } @tokens;

cmp_ok(
    @dollar_tokens, '==', 2,
    'Dollar tokens found'
);
