-- Convert schema 'lib/auto/Tapper/Schema/Tapper-Schema-TestrunDB-4.001001-SQLite.sql' to 'lib/auto/Tapper/Schema/Tapper-Schema-TestrunDB-4.001003-SQLite.sql':;

BEGIN;

CREATE TABLE denied_host (
  id INTEGER PRIMARY KEY NOT NULL,
  queue_id INT(11) NOT NULL,
  host_id INT(11) NOT NULL,
  FOREIGN KEY (host_id) REFERENCES host(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (queue_id) REFERENCES queue(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX denied_host_idx_host_id ON denied_host (host_id);

CREATE INDEX denied_host_idx_queue_id ON denied_host (queue_id);

CREATE UNIQUE INDEX constraint_name02 ON host (name);


COMMIT;

