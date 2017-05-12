-- Convert schema '../Tapper-Schema/lib/auto/Tapper/Schema/Tapper-Schema-TestrunDB-4.001001-MySQL.sql' to 'Tapper::Schema::TestrunDB v4.001002':;

BEGIN;

SET foreign_key_checks=0;

CREATE TABLE denied_host (
  id integer(11) NOT NULL auto_increment,
  queue_id integer(11) NOT NULL,
  host_id integer(11) NOT NULL,
  INDEX denied_host_idx_host_id (host_id),
  INDEX denied_host_idx_queue_id (queue_id),
  PRIMARY KEY (id),
  CONSTRAINT denied_host_fk_host_id FOREIGN KEY (host_id) REFERENCES host (id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT denied_host_fk_queue_id FOREIGN KEY (queue_id) REFERENCES queue (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

SET foreign_key_checks=1;

ALTER TABLE message CHANGE COLUMN message message text,
                    CHANGE COLUMN type type VARCHAR(255);

ALTER TABLE state CHANGE COLUMN state state text;

ALTER TABLE testrun_scheduling CHANGE COLUMN status status VARCHAR(255) DEFAULT 'prepare';


COMMIT;

