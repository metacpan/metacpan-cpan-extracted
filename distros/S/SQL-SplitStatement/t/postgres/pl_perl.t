use strict;
use warnings;

use SQL::SplitStatement;

use Test::More tests => 1;
use Test::Differences;

my $sql_code = <<'SQL';
CREATE FUNCTION funcname (argument-types) RETURNS return-type AS $perl$
    # PL/Perl function body
    $arg->{things} = 'stuff';
$perl$ LANGUAGE plperl;
SQL

my $splitter = SQL::SplitStatement->new;
my @statements = $splitter->split( $sql_code );

eq_or_diff "$statements[-1]\n", <<'DONERIGHT', 'does not strip dollar quoted delimeters';
CREATE FUNCTION funcname (argument-types) RETURNS return-type AS $perl$
    # PL/Perl function body
    $arg->{things} = 'stuff';
$perl$ LANGUAGE plperl
DONERIGHT
