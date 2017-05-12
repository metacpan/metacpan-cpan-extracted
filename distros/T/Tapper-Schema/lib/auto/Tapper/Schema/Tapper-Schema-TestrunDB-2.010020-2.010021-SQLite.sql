-- Convert schema 'upgrades/Tapper-Schema-TestrunDB-2.010020-SQLite.sql' to 'upgrades/Tapper-Schema-TestrunDB-2.010021-SQLite.sql':;

BEGIN;

CREATE TABLE queue_host (
  id INTEGER PRIMARY KEY NOT NULL,
  queue_id INT(11) NOT NULL,
  host_id INT
);

CREATE INDEX queue_host_idx_host_id ON queue_host (host_id);

CREATE INDEX queue_host_idx_queue_id ON queue_host (queue_id);


COMMIT;

