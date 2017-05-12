-- Convert schema 'lib/auto/Tapper/Schema/Tapper-Schema-TestrunDB-4.001003-PostgreSQL.sql' to 'lib/auto/Tapper/Schema/Tapper-Schema-TestrunDB-4.001004-PostgreSQL.sql':;

BEGIN;

ALTER TABLE preconditiontype ALTER COLUMN name TYPE character varying(255);

CREATE INDEX testrun_idx_created_at on testrun (created_at);

CREATE INDEX testrun_scheduling_idx_created_at on testrun_scheduling (created_at);

CREATE INDEX testrun_scheduling_idx_status on testrun_scheduling (status);

COMMIT;

