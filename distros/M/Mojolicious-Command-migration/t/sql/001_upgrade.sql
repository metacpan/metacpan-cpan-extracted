-- Convert schema 'testshare/migrations/_source/deploy/1/001_auto.yml' to 'testshare/migrations/_source/deploy/2/001_auto.yml':;

BEGIN;

ALTER TABLE test ADD COLUMN name varchar(255) NOT NULL DEFAULT '';


COMMIT;

