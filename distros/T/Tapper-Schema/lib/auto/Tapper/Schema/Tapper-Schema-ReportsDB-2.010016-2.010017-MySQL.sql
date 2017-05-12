-- Convert schema 'upgrades/Tapper-Schema-ReportsDB-2.010016-MySQL.sql' to 'Tapper::Schema::ReportsDB v2.010017':

BEGIN;

ALTER TABLE report ADD COLUMN peeraddr VARCHAR(20) DEFAULT '',
                   ADD COLUMN peerport VARCHAR(20) DEFAULT '',
                   ADD COLUMN peerhost VARCHAR(255) DEFAULT '';
ALTER TABLE reportsection CHANGE COLUMN language_description language_description text;

COMMIT;
