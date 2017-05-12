-- Convert schema 'upgrades/Tapper-Schema-ReportsDB-2.010035-SQLite.sql' to 'upgrades/Tapper-Schema-ReportsDB-2.010036-SQLite.sql':;

BEGIN;

ALTER TABLE reportsection ADD COLUMN ticket_url VARCHAR(255);

ALTER TABLE reportsection ADD COLUMN wiki_url VARCHAR(255);

ALTER TABLE reportsection ADD COLUMN planning_id VARCHAR(255);


COMMIT;

