-- Convert schema 'lib/auto/Tapper/Schema/Tapper-Schema-ReportsDB-4.001001-MySQL.sql' to 'Tapper::Schema::ReportsDB v4.001002':;

BEGIN;

ALTER TABLE notification_event CHANGE COLUMN type type VARCHAR(255);

ALTER TABLE report CHANGE COLUMN suite_version suite_version VARCHAR(255),
                   CHANGE COLUMN reportername reportername VARCHAR(255) DEFAULT '',
                   CHANGE COLUMN peeraddr peeraddr VARCHAR(255) DEFAULT '',
                   CHANGE COLUMN peerport peerport VARCHAR(255) DEFAULT '',
                   CHANGE COLUMN machine_name machine_name VARCHAR(255) DEFAULT '',
                   ADD INDEX report_idx_created_at (created_at);

ALTER TABLE reportsection CHANGE COLUMN ram ram VARCHAR(255),
                          CHANGE COLUMN uptime uptime VARCHAR(255),
                          CHANGE COLUMN xen_hvbits xen_hvbits VARCHAR(255),
                          ADD INDEX reportsection_idx_report_id (report_id);

ALTER TABLE reporttopic CHANGE COLUMN name name VARCHAR(255) DEFAULT '';

ALTER TABLE suite CHANGE COLUMN type type VARCHAR(255) NOT NULL;


COMMIT;

