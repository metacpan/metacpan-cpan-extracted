-- Convert schema 'upgrades/Tapper-Schema-ReportsDB-2.010011-SQLite.sql' to 'upgrades/Tapper-Schema-ReportsDB-2.010012-SQLite.sql':

BEGIN;

CREATE INDEX report_idx_suite_id_report_rep ON report (suite_id);
CREATE INDEX reportcomment_idx_report_id_re_reportcommen ON reportcomment (report_id);
CREATE INDEX reportcomment_idx_user_id_repo_reportcommen ON reportcomment (user_id);
CREATE INDEX reportfile_idx_report_id_repor_reportfil ON reportfile (report_id);
CREATE INDEX reportgroup_idx_report_id_repo_reportgrou ON reportgroup (report_id);
CREATE INDEX reportsection_idx_report_id_re_reportsectio ON reportsection (report_id);
CREATE INDEX reporttopic_idx_report_id_repo_reporttopi ON reporttopic (report_id);



COMMIT;
