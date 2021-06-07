#!/usr/bin/env perl

use strict;
use warnings;

use SQL::SplitStatement;

use Test::More tests => 3;

# Bug report by Alexander Sennhauser <as@open.ch>

my @input_statements;
my $sql_code;

$input_statements[0] = <<'SQL';
DROP TRIGGER IF EXISTS user_change_password;
SQL

$input_statements[1] = <<'SQL';

DELIMITER //
SQL

$input_statements[2] = <<'SQL';

CREATE TRIGGER user_change_password AFTER UPDATE ON user
FOR EACH ROW my_block: BEGIN
    IF NEW.password != OLD.password THEN
        UPDATE user_authentication_results AS uar
        SET password_changed = 1
        WHERE uar.user_id = NEW.user_id;
    END IF;
END my_block;
/
-- Illegal, just to check that a / inside a custom delimiter
-- can't split the statement.
set localvariable datatype;
set localvariable = parameter2;
select fields from table where field1 = parameter1;
//
SQL

$input_statements[3] = <<'SQL';

delimiter ;
SQL

$input_statements[4] = <<'SQL';

CREATE TABLE foo (
    foo_field_1 VARCHAR,
    foo_field_2 VARCHAR
);
SQL

$input_statements[5] = <<'SQL';

CREATE TABLE bar (
    bar_field_1 VARCHAR,
    bar_field_2 VARCHAR
)
SQL

chomp @input_statements;
$sql_code = join '', @input_statements;

my $splitter;
my @statements;

$splitter = SQL::SplitStatement->new(
    keep_terminator       => 1,
    keep_extra_spaces     => 1,
    keep_comments         => 1,
    keep_empty_statements => 1
);

@statements = $splitter->split( $sql_code );

is_deeply (
    \@statements, \@input_statements,
    'Popular custom delimiter'
);

$input_statements[1] = <<'SQL';

DELIMITER "+123-Wak+ka@#> > >@|*|@< < <#@ak+kaW-321+"
SQL

$input_statements[2] = <<'SQL';

CREATE TRIGGER user_change_password AFTER UPDATE ON user
FOR EACH ROW my_block: BEGIN
    IF NEW.password != OLD.password THEN
        UPDATE user_authentication_results AS uar
        SET password_changed = 1
        WHERE uar.user_id = NEW.user_id;
    END IF;
END my_block;
set localvariable datatype;
set localvariable = parameter2;
select fields from table where field1 = parameter1;
+123-Wak+ka@#> > >@|*|@< < <#@ak+kaW-321+
SQL

chomp( $input_statements[1], $input_statements[2] );
$sql_code = join '', @input_statements;

@statements = $splitter->split( $sql_code );

is_deeply (
    \@statements, \@input_statements,
    'Quoted unusual custom delimiter'
);

$input_statements[1] = <<'SQL';

DELIMITER +123-Wak+ka@#> > >@|*|@< < <#@ak+kaW-321+
SQL

chomp $input_statements[1];
$sql_code = join '', @input_statements;

@statements = $splitter->split( $sql_code );

is_deeply (
    \@statements, \@input_statements,
    'Unquoted unusual custom delimiter'
);
