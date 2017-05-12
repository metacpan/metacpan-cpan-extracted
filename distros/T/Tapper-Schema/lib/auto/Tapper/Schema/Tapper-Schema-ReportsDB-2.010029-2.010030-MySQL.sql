-- Convert schema 'upgrades/Tapper-Schema-ReportsDB-2.010029-MySQL.sql' to 'Tapper::Schema::ReportsDB v2.010030':;

-- differences manually added (sschwigo)

--
-- View: view_testrun_overview_reports
--
CREATE VIEW view_testrun_overview_reports AS
    select rgts.testrun_id    as rgt_testrun_id,        max(rgt.report_id) as primary_report_id,        rgts.success_ratio as rgts_success_ratio from reportgrouptestrun rgt, reportgrouptestrunstats rgts where rgt.testrun_id=rgts.testrun_id group by rgt.testrun_id;

--
-- View: view_testrun_overview
--
CREATE VIEW view_testrun_overview AS
    select vtor.*,        r.machine_name,        r.created_at,        r.suite_id,        s.name as suite_name from view_testrun_overview_reports vtor,      report r,      suite s where vtor.primary_report_id=r.id and       r.suite_id=s.id;

