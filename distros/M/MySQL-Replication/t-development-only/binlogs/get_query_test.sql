-- init default schema

DROP DATABASE IF EXISTS replication_test;
CREATE DATABASE replication_test;

USE replication_test;

-- set defaults so that the binlog matches the test harness

SET @@session.auto_increment_increment=1;
SET @@session.auto_increment_offset=1;

-- test reading from multiple binlogs

DROP TABLE IF EXISTS get_query_test;
CREATE TABLE get_query_test (
  id   INT          NOT NULL,
  name VARCHAR(255) NOT NULL
);

INSERT INTO get_query_test ( id, name ) VALUES ( 1, 'A' );
INSERT INTO get_query_test ( id, name ) VALUES ( 2, 'B' );
INSERT INTO get_query_test ( id, name ) VALUES ( 3, 'C' );
INSERT INTO get_query_test ( id, name ) VALUES ( 4, 'D' );

FLUSH LOGS;
INSERT INTO get_query_test ( id, name ) VALUES ( 5,  'E' );
INSERT INTO get_query_test ( id, name ) VALUES ( 6,  'F' );
INSERT INTO get_query_test ( id, name ) VALUES ( 7,  'G' );
INSERT INTO get_query_test ( id, name ) VALUES ( 8,  'H' );
INSERT INTO get_query_test ( id, name ) VALUES ( 9,  'I' );
INSERT INTO get_query_test ( id, name ) VALUES ( 10, 'J' );

FLUSH LOGS;
INSERT INTO get_query_test ( id, name ) VALUES ( 11, 'K' );
INSERT INTO get_query_test ( id, name ) VALUES ( 12, 'L' );
INSERT INTO get_query_test ( id, name ) VALUES ( 13, 'M' );
INSERT INTO get_query_test ( id, name ) VALUES ( 14, 'N' );
INSERT INTO get_query_test ( id, name ) VALUES ( 15, 'O' );
INSERT INTO get_query_test ( id, name ) VALUES ( 16, 'P' );

-- test handling of multiple schemas

DROP DATABASE IF EXISTS replication_test1;
DROP DATABASE IF EXISTS replication_test2;

CREATE DATABASE replication_test1;
CREATE DATABASE replication_test2;

USE replication_test1;
CREATE TABLE get_query_test                   ( id INT NOT NULL, name VARCHAR(255) NOT NULL );
CREATE TABLE replication_test2.get_query_test ( id INT NOT NULL, name VARCHAR(255) NOT NULL );

INSERT INTO get_query_test                   VALUES ( 1, 'A' );
INSERT INTO replication_test2.get_query_test VALUES ( 1, 'A' );

-- test AUTO_INCREMENT_ID queries
--   using SIGNED since MySQL seems to be buggy with BIGINT UNSIGNED:
--   see http://bugs.mysql.com/bug.php?id=20964

USE replication_test;

DROP TABLE IF EXISTS get_query_test;
CREATE TABLE get_query_test (
  id   BIGINT       NOT NULL PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(255) NOT NULL
);

INSERT INTO get_query_test( name )     VALUES ( 'A' );
INSERT INTO get_query_test( name )     VALUES ( 'B' );
INSERT INTO get_query_test( id, name ) VALUES ( 9223372036854775700, 'C' );
INSERT INTO get_query_test( id, name ) VALUES ( 9223372036854775701, 'D' );
INSERT INTO get_query_test( name )     VALUES ( 'E' );
INSERT INTO get_query_test( name )     VALUES ( 'F' );
INSERT INTO get_query_test( id, name ) VALUES ( 5, 'G' );
INSERT INTO get_query_test( name )     VALUES ( 'H' );

-- test LAST_INSERT_ID() queries

DROP TABLE IF EXISTS get_query_test;
CREATE TABLE get_query_test (
  id   BIGINT       NOT NULL PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(255)
);

INSERT INTO get_query_test( name )     VALUES ( 'A' );
INSERT INTO get_query_test( name )     VALUES ( LAST_INSERT_ID() );
INSERT INTO get_query_test( name )     VALUES ( LAST_INSERT_ID() );
INSERT INTO get_query_test( id, name ) VALUES ( 4, LAST_INSERT_ID() );
INSERT INTO get_query_test( id, name ) VALUES ( 5, LAST_INSERT_ID() );
INSERT INTO get_query_test( name )     VALUES ( LAST_INSERT_ID() );
INSERT INTO get_query_test( name )     VALUES ( LAST_INSERT_ID() );
INSERT INTO get_query_test( id, name ) VALUES ( 9223372036854775700, LAST_INSERT_ID() );
INSERT INTO get_query_test( id, name ) VALUES ( 9223372036854775701, LAST_INSERT_ID() );
INSERT INTO get_query_test( name )     VALUES ( LAST_INSERT_ID() );
INSERT INTO get_query_test( name )     VALUES ( LAST_INSERT_ID() );
INSERT INTO get_query_test( id, name ) VALUES ( 8, LAST_INSERT_ID() );
INSERT INTO get_query_test( id, name ) VALUES ( 9, LAST_INSERT_ID() );
INSERT INTO get_query_test( name )     VALUES ( LAST_INSERT_ID() );
INSERT INTO get_query_test( name )     VALUES ( LAST_INSERT_ID() );

-- test RAND() queries

SET @@RAND_SEED1 = 123456;
SET @@RAND_SEED2 = 234567;
INSERT INTO get_query_test( name ) VALUES ( RAND() );
INSERT INTO get_query_test( name ) VALUES ( RAND() );
INSERT INTO get_query_test( name ) VALUES ( RAND() );
INSERT INTO get_query_test( name ) VALUES ( RAND() );
INSERT INTO get_query_test( name ) VALUES ( RAND() );

-- test user variables

SET @test1 = 1;
INSERT INTO get_query_test( name ) VALUES ( @test1 );

SET @test1 := 9223372036854775712;
INSERT INTO get_query_test( id, name ) VALUES ( @test1, 'test' );

SET @test1 := 1.5;
INSERT INTO get_query_test( name ) VALUES ( @test1 );

SET @test1 := -1.5;
INSERT INTO get_query_test( name ) VALUES ( @test1 );

SET @test1 = 1234567890.1234;
INSERT INTO get_query_test( name ) VALUES ( @test1 );

SET @test1 = -1234567890.1234;
INSERT INTO get_query_test( name ) VALUES ( @test1 );

SET @test1 = 12345678901234567890123456789012345.123456789012345678901234567890;
INSERT INTO get_query_test( name ) VALUES ( @test1 );

SET @test1 = -12345678901234567890123456789012345.123456789012345678901234567890;
INSERT INTO get_query_test( name ) VALUES ( @test1 );

SET @test1 = "test";
INSERT INTO get_query_test( name ) VALUES ( @test1 );

SET @test1 = "A long sentance doesn't fit in a quad";
INSERT INTO get_query_test( name ) VALUES ( @test1 );

SET @test1 = LAST_INSERT_ID() + 1, @test2 = NULL;
INSERT INTO get_query_test VALUES ( @test1, @test2 );

-- test NOW()

INSERT INTO get_query_test( name ) VALUES ( NOW() );

-- transactions

DROP TABLE IF EXISTS get_query_test;
CREATE TABLE get_query_test (
  id   INT          NOT NULL,
  name VARCHAR(255)
) ENGINE=InnoDB;

BEGIN;
INSERT INTO get_query_test VALUES ( 1,  'trans-1' );
INSERT INTO get_query_test VALUES ( 2,  'trans-2' );
COMMIT;

BEGIN WORK;
INSERT INTO get_query_test VALUES ( 3,  'trans-3' );
INSERT INTO get_query_test VALUES ( 4,  'trans-4' );
COMMIT WORK;

BEGIN;
INSERT INTO get_query_test VALUES ( 5,  'trans-5' );
INSERT INTO get_query_test VALUES ( 6,  'trans-6' );
ROLLBACK;

BEGIN WORK;
INSERT INTO get_query_test VALUES ( 7,  'trans-7' );
INSERT INTO get_query_test VALUES ( 8,  'trans-8' );
ROLLBACK WORK;

START TRANSACTION;
INSERT INTO get_query_test VALUES ( 9,  'trans-9' );
INSERT INTO get_query_test VALUES ( 10, 'trans-A' );
COMMIT;

-- skip queries that aren't from this server-id (hex edit the binlog to change
INSERT INTO get_query_test( name ) VALUES ( 'Server-id check. These need to be hex edited in the binlog' );
INSERT INTO get_query_test( name ) VALUES ( 'Server-id 1' );
INSERT INTO get_query_test( name ) VALUES ( 'Server-id 31-1' );
INSERT INTO get_query_test( name ) VALUES ( 'Server-id 2' );
INSERT INTO get_query_test( name ) VALUES ( 'Server-id 31-2' );
INSERT INTO get_query_test( name ) VALUES ( 'Server-id 31-3' );
INSERT INTO get_query_test( name ) VALUES ( 'Server-id 3' );
INSERT INTO get_query_test( name ) VALUES ( 'Server-id 31-4' );
INSERT INTO get_query_test( name ) VALUES ( 'Server-id 31-5' );

-- add trailing queries so that we're not stuck on the last test waiting for data
INSERT INTO get_query_test( name ) VALUES ( 'Done.' );
INSERT INTO get_query_test( name ) VALUES ( 'Done.' );
INSERT INTO get_query_test( name ) VALUES ( 'Done.' );
