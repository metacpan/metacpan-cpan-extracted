-- Convert schema 'upgrades/Tapper-Schema-TestrunDB-2.010020-MySQL.sql' to 'Tapper::Schema::TestrunDB v2.010021':;

BEGIN;

SET foreign_key_checks=0;

CREATE TABLE `queue_host` (
  id integer(11) NOT NULL auto_increment,
  queue_id integer(11) NOT NULL,
  host_id integer,
  INDEX queue_host_idx_host_id (host_id),
  INDEX queue_host_idx_queue_id (queue_id),
  PRIMARY KEY (id),
  CONSTRAINT queue_host_fk_host_id FOREIGN KEY (host_id) REFERENCES `host` (id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT queue_host_fk_queue_id FOREIGN KEY (queue_id) REFERENCES `queue` (id)
) ENGINE=InnoDB;

SET foreign_key_checks=1;

ALTER TABLE testrun_scheduling CHANGE COLUMN status status VARCHAR(255) DEFAULT 'prepare';


COMMIT;

