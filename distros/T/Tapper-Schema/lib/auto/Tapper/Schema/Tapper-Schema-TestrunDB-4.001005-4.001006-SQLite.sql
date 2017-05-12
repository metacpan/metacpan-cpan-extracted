-- Convert schema '/home/local/ANT/caldrin/perl5/perls/perl-5.16.2/lib/site_perl/5.16.2/auto/Tapper/Schema/Tapper-Schema-TestrunDB-4.001005-SQLite.sql' to '/home/local/ANT/caldrin/perl5/perls/perl-5.16.2/lib/site_perl/5.16.2/auto/Tapper/Schema/Tapper-Schema-TestrunDB-4.001006-SQLite.sql':;

BEGIN;

CREATE TEMPORARY TABLE host_temp_alter (
  id INTEGER PRIMARY KEY NOT NULL,
  name VARCHAR(255) DEFAULT '',
  comment VARCHAR(255) DEFAULT '',
  free TINYINT DEFAULT 0,
  active TINYINT DEFAULT 0,
  is_deleted TINYINT DEFAULT 0,
  pool_free INT,
  pool_id INT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME,
  FOREIGN KEY (pool_id) REFERENCES host(id) ON DELETE CASCADE ON UPDATE CASCADE
);

INSERT INTO host_temp_alter( id, name, comment, free, active, is_deleted, created_at, updated_at) SELECT id, name, comment, free, active, is_deleted, created_at, updated_at FROM host;

DROP TABLE host;

CREATE TABLE host (
  id INTEGER PRIMARY KEY NOT NULL,
  name VARCHAR(255) DEFAULT '',
  comment VARCHAR(255) DEFAULT '',
  free TINYINT DEFAULT 0,
  active TINYINT DEFAULT 0,
  is_deleted TINYINT DEFAULT 0,
  pool_free INT,
  pool_id INT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME,
  FOREIGN KEY (pool_id) REFERENCES host(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX host_idx_pool_id03 ON host (pool_id);

CREATE UNIQUE INDEX constraint_name03 ON host (name);

INSERT INTO host SELECT id, name, comment, free, active, is_deleted, pool_free, pool_id, created_at, updated_at FROM host_temp_alter;

DROP TABLE host_temp_alter;


COMMIT;

