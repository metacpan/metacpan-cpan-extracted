-- Convert schema 'upgrades/Tapper-Schema-ReportsDB-2.010016-SQLite.sql' to 'upgrades/Tapper-Schema-ReportsDB-2.010017-SQLite.sql':

BEGIN;

ALTER TABLE report ADD COLUMN peeraddr VARCHAR(20) DEFAULT '';
ALTER TABLE report ADD COLUMN peerport VARCHAR(20) DEFAULT '';
ALTER TABLE report ADD COLUMN peerhost VARCHAR(255) DEFAULT '';










COMMIT;
