-- This SQL script is used to completely wipe a database if you really
-- need to start again from scratch. Normally this is only necessary
-- during the development process.

-- psql -d pkgforge -h pkgforge -U pkgforge_admin -f registry-wipe.sql

-- AFTER RUNNING THIS YOU WILL HAVE NO DATA! 

DROP TABLE task CASCADE;
DROP TABLE task_status CASCADE;

DROP TABLE job CASCADE;
DROP TABLE job_status CASCADE;

DROP TABLE builder CASCADE;
DROP TABLE build_log CASCADE;

DROP TABLE platform CASCADE;

DROP FUNCTION update_modification_time();
DROP FUNCTION check_task(INTEGER,INTEGER);

DROP ROLE pkgforge_incoming;
DROP ROLE pkgforge_builder;
DROP ROLE pkgforge_web;
