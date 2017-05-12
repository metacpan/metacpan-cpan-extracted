-- Convert schema 'lib/auto/Tapper/Schema/Tapper-Schema-ReportsDB-4.001001-PostgreSQL.sql' to 'lib/auto/Tapper/Schema/Tapper-Schema-ReportsDB-4.001002-PostgreSQL.sql':;

BEGIN;

--
-- temporarily drop View: "view_testrun_overview"
--
DROP VIEW "view_testrun_overview";

ALTER TABLE report ALTER COLUMN suite_version TYPE character varying(255);

ALTER TABLE report ALTER COLUMN reportername TYPE character varying(255);

ALTER TABLE report ALTER COLUMN peeraddr TYPE character varying(255);

ALTER TABLE report ALTER COLUMN peerport TYPE character varying(255);

ALTER TABLE report ALTER COLUMN machine_name TYPE character varying(255);

ALTER TABLE reportsection ALTER COLUMN ram TYPE character varying(255);

ALTER TABLE reportsection ALTER COLUMN uptime TYPE character varying(255);

ALTER TABLE reportsection ALTER COLUMN xen_hvbits TYPE character varying(255);

ALTER TABLE reporttopic ALTER COLUMN name TYPE character varying(255);

ALTER TABLE suite ALTER COLUMN type TYPE character varying(255);

CREATE INDEX report_idx_created_at on report (created_at);

CREATE INDEX reportsection_idx_report_id on reportsection (report_id);

CREATE VIEW "view_testrun_overview" ( "vtor_primary_report_id", "vtor_rgt_testrun_id", "vtor_rgts_success_ratio", "report_id", "report_machine_name", "report_created_at", "report_suite_id", "report_suite_name" ) AS
    select   vtor.primary_report_id  as vtor_primary_report_id        , vtor.rgt_testrun_id     as vtor_rgt_testrun_id        , vtor.rgts_success_ratio as vtor_rgts_success_ratio        , report.id               as report_id        , report.machine_name     as report_machine_name        , report.created_at       as report_created_at        , report.suite_id         as report_suite_id        , suite.name              as report_suite_name from view_testrun_overview_reports vtor,      report report,      suite suite where CAST(vtor.primary_report_id as INTEGER)=report.id and       report.suite_id=suite.id
;

COMMIT;

