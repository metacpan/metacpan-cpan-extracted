-- Revert myapp:test_migration from sqlite

BEGIN;

DROP TABLE IF EXISTS `users`;

COMMIT;
