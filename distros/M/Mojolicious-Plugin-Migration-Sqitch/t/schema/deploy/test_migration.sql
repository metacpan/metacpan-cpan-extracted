-- Deploy myapp:test_migration to sqlite

BEGIN;

CREATE TABLE IF NOT EXISTS users (
  id INT PRIMARY KEY AUTO_INCREMENT,
  username VARCHAR(50) NOT NULL
);

COMMIT;
