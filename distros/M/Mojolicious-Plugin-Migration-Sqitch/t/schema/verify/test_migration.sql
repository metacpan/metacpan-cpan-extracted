-- Verify myapp:test_migration on sqlite

BEGIN;

SELECT id,username FROM users;

ROLLBACK;
