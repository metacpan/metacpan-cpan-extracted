-- Convert schema 'upgrades/Tapper-Schema-ReportsDB-2.010033-MySQL.sql' to 'Tapper::Schema::ReportsDB v2.010037':;

BEGIN;


ALTER TABLE reportsection ADD COLUMN ticket_url VARCHAR(255),
                          ADD COLUMN wiki_url VARCHAR(255),
                          ADD COLUMN planning_id VARCHAR(255),
                          ADD COLUMN tags VARCHAR(255);

ALTER TABLE tap ADD COLUMN tap_is_archive integer(11);


COMMIT;

