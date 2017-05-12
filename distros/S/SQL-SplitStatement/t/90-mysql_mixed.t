#!/usr/bin/env perl

use strict;
use warnings;

use SQL::SplitStatement;

use Test::More tests => 9;

my $sql_code;

$sql_code = <<'SQL';

DELIMITER $$

CREATE PROCEDURE `3blocks`(n INT)
BEGIN
  DECLARE newn INT DEFAULT n;
  BEGIN
    DECLARE newn INT DEFAULT n * 2;
    IF TRUE THEN
      BEGIN
        DECLARE newn INT DEFAULT n * 3;
        SELECT n 'Orig', 3 'Run', newn 'New Factor';
      END;
    END IF;
    SELECT n 'Orig', 2 'Run', newn 'New Factor';
  END;
  SELECT n 'Orig', 1 'Run', newn 'New Factor';
END$$

DELIMITER ;

CALL `3blocks`(10);

DELIMITER $nando$

CREATE PROCEDURE `3blocks`(n INT)
BEGIN
  DECLARE newn INT DEFAULT n;
  BEGIN
    DECLARE newn INT DEFAULT n * 2;
    IF TRUE THEN
      BEGIN
        DECLARE newn INT DEFAULT n * 3;
        SELECT n 'Orig', 3 'Run', newn 'New Factor';
      END;
    END IF;
    SELECT n 'Orig', 2 'Run', newn 'New Factor';
  END;
  SELECT n 'Orig', 1 'Run', newn 'New Factor';
END$nando$

DELIMITER ;

CALL `3blocks`(10);

SQL

my $splitter;
my @statements;
my @endings;

$splitter = SQL::SplitStatement->new;
@statements = $splitter->split( $sql_code );

cmp_ok(
    @statements, '==', 8,
    'Statements correctly split'
);

@endings = qw|
    $$
    END
    ;
    `3blocks`(10)
    $nando$
    END
    ;
    `3blocks`(10)
|;

like( $statements[$_], qr/\Q$endings[$_]\E$/, 'Statement ' . ($_+1) . ' check' )
    for 0..$#endings;
