-- Use this SQL script to setup an empty database. The work is done
-- inside a transaction so if anything fails you do not end up with a
-- database in a peculiar state.

-- psql -d pkgforge -h pkgforge -U pkgforge_admin -f registry-setup.sql

-- Note that every table has an 'id' field. This is mainly to satisfy
-- DBIx::Class which, like many ORM systems, prefers to use unique
-- integer identifiers to keep track of the mapping between rows and
-- objects. This is not usually meant to be exposed to the user.

BEGIN;

-------------------------------------------------------------------------------
-- Table: task_status
--
-- When each job is registered it is split into tasks, one per target
-- platform. This table stores the possible task status levels.

CREATE TABLE task_status (
    id     SERIAL      PRIMARY KEY,
    name   VARCHAR(20) NOT NULL UNIQUE
);

-- If adding a new status do not forget to increment the sequence number.

INSERT INTO task_status ( id, name ) VALUES ( 0, 'needs build' );
INSERT INTO task_status ( id, name ) VALUES ( 1, 'building' );
INSERT INTO task_status ( id, name ) VALUES ( 2, 'fail' );
INSERT INTO task_status ( id, name ) VALUES ( 3, 'success' );
INSERT INTO task_status ( id, name ) VALUES ( 4, 'cancelled' );
SELECT setval('task_status_id_seq',5);

-------------------------------------------------------------------------------
-- Table: job_status
--
-- The status for a job is tracked from the moment it is first
-- encountered in the incoming queue. The first 5 states can fly by
-- extremely quickly but are very useful for debugging if a job fails
-- at any stage in the acceptance process.

-- Each job is represented by a set of tasks, this means that the
-- status can be more complicated for a job than a task. Some tasks
-- may succeed and others may fail.

CREATE TABLE job_status (
    id   SERIAL      PRIMARY KEY,
    name VARCHAR(20) NOT NULL UNIQUE
);

-- If adding a new status do not forget to increment the sequence number.

INSERT INTO job_status( id, name ) VALUES ( 0, 'incoming' );
INSERT INTO job_status( id, name ) VALUES ( 1, 'valid' );
INSERT INTO job_status( id, name ) VALUES ( 2, 'invalid' );
INSERT INTO job_status( id, name ) VALUES ( 3, 'accepted' );
INSERT INTO job_status( id, name ) VALUES ( 4, 'registered' );
INSERT INTO job_status( id, name ) VALUES ( 5, 'partial fail' );
INSERT INTO job_status( id, name ) VALUES ( 6, 'fail' );
INSERT INTO job_status( id, name ) VALUES ( 7, 'partial success' );
INSERT INTO job_status( id, name ) VALUES ( 8, 'success' );
INSERT INTO job_status( id, name ) VALUES ( 9, 'cancelled' );
SELECT setval('job_status_id_seq',10);

-------------------------------------------------------------------------------
-- Table: job
--
-- A job has:
--      uuid      - the external identifier known to the submitter
--      submitter - username for the submitter
--      status    - current status of the job
--      size      - size of the job (in bytes) - NOT CURRENTLY USED
--      modtime   - last time this job entry was modified
--
-- This is, deliberately, not a complete representation of everything
-- in the PkgForge::Job specification. This is everything necessary to
-- track and schedule the individual tasks.

-- There is a trigger (see later on), named 'job_change', attached to
-- this table which updates the modification time (modtime) when ever
-- a row is updated.

CREATE DOMAIN JOB_UUID AS VARCHAR(50) CHECK( VALUE ~ '^[A-Za-z0-9_.-]+$' );

CREATE TABLE job (
    id         SERIAL      PRIMARY KEY,
    uuid       JOB_UUID    NOT NULL UNIQUE,
    submitter  VARCHAR(50),
    status     INTEGER     NOT NULL REFERENCES job_status(id) DEFAULT 0,
    size       INTEGER,
    modtime    TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp
);

-------------------------------------------------------------------------------
-- Table: platform
--
-- This table holds the list of target platforms. They may be inactive
-- (i.e. old and no longer supported) in which case new tasks will not
-- be registered for that platform.
--
-- A platform has:
--      name   - The name (e.g. sl5 or f13)
--      arch   - The architecture (e.g. i386 or x86_64)
--      active - A boolean, controls whether or not to register tasks
--      auto   - A boolean, controls automatic task registration
--
-- Note that the combination of name and arch MUST be unique.

CREATE TABLE platform (
    id     SERIAL      PRIMARY KEY,
    name   VARCHAR(10) NOT NULL,
    arch   VARCHAR(10) NOT NULL,
    active BOOLEAN     NOT NULL DEFAULT FALSE,
    auto   BOOLEAN     NOT NULL DEFAULT FALSE,
    CONSTRAINT name_arch UNIQUE(name,arch)
);

INSERT INTO platform ( name, arch, active ) VALUES ( 'sl5', 'i386', TRUE );
INSERT INTO platform ( name, arch, active ) VALUES ( 'sl5', 'x86_64', TRUE );
INSERT INTO platform ( name, arch, active ) VALUES ( 'f13', 'i386', TRUE );
INSERT INTO platform ( name, arch, active ) VALUES ( 'f13', 'x86_64', TRUE );

-------------------------------------------------------------------------------
-- Table: task
--
-- A job is split into tasks, one per target platform.
--
-- A task has:
--      job      - The ID of the job
--      platform - The ID of the target platform
--      status   - The current status of the task
--      modtime  - last time this task entry was modified
--
-- Note that there is a constraint which ensures each job can only be
-- registered for a specific platform once.
--
-- There is a trigger (see later on), named 'task_change', attached to
-- this table which updates the modification time (modtime) when ever
-- a row is updated.

CREATE TABLE task (
    id         SERIAL   PRIMARY KEY,
    job        INTEGER  NOT NULL REFERENCES job(id) ON DELETE CASCADE,
    platform   INTEGER  NOT NULL REFERENCES platform(id),
    status     INTEGER  NOT NULL REFERENCES task_status(id) DEFAULT 0,
    modtime    TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
    CONSTRAINT job_plat UNIQUE(job,platform)
);

-------------------------------------------------------------------------------
-- Table: builder
--
-- A platform may have multiple build daemons. This table is used to
-- keep track of the available builders. Note that a platform may be
-- active but have no registered build daemons, when a build daemon is
-- later added it will then just work through any registered tasks.
--
-- A builder has:
--      name     - A unique name used to identify the build daemon
--      platform - The ID of the target platform
--      current  - The ID of the current task being worked on
--      modtime  - last time this builder entry was modified
--
-- Note that there is a constraint which uses the 'check_task'
-- function to ensure that when the current task is set for a builder
-- it is for the appropriate platform.

CREATE OR REPLACE FUNCTION check_task(t INTEGER, p INTEGER)
RETURNS BOOLEAN AS $$
DECLARE correct BOOLEAN;
BEGIN
        SELECT  (platform = $2) INTO correct
        FROM    task
        WHERE   id = $1;

        RETURN correct;
END;
$$  LANGUAGE plpgsql;

CREATE DOMAIN BUILDER_NAME AS VARCHAR(50);

CREATE TABLE builder (
    id         SERIAL       PRIMARY KEY,
    name       BUILDER_NAME NOT NULL UNIQUE,
    platform   INTEGER      NOT NULL REFERENCES platform(id),
    current    INTEGER      UNIQUE   REFERENCES task(id),
    modtime    TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
    CONSTRAINT task_platform CHECK( check_task(current,platform) )
);

-------------------------------------------------------------------------------
-- Table: build_log
--
-- This table is used to keep a log of all build attempts. Note that
-- it is possible a task may be attempted more than once by the same
-- or different builders for a particular platform.

-- Note also that we deliberately avoid having references to the job
-- and builder tables. It is entirely possible that a job or builder
-- entry may be deleted at a later point so we do not want references
-- to block deletions.

CREATE TABLE build_log (
    id         SERIAL       PRIMARY KEY,
    job        JOB_UUID     NOT NULL,
    platform   INTEGER      NOT NULL REFERENCES platform(id),
    builder    BUILDER_NAME NOT NULL,
    modtime    TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp
);

-------------------------------------------------------------------------------
-- Rules and Triggers
--

-- Rule: log_builds
--
-- Every time the 'current' task for any builder changes it will be
-- noted in the build_log table along with the time it occurred.

CREATE OR REPLACE FUNCTION update_build_log()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
  j_uuid JOB_UUID;
BEGIN

   -- Only interested in changes to the 'current' task
   IF NEW.current IS NULL OR NEW.current = OLD.current THEN
     RETURN NEW;
   END IF;

   SELECT j.uuid INTO j_uuid
     FROM task AS t
     JOIN job  AS j ON j.id = t.job
     WHERE t.id = NEW.current
     LIMIT 1;

   INSERT INTO build_log ( job, platform, builder )
          VALUES ( j_uuid, NEW.platform, NEW.name );

   RETURN NEW;
END;
$$;

CREATE TRIGGER log_builds AFTER UPDATE
    ON builder FOR EACH ROW EXECUTE PROCEDURE 
    update_build_log();


--CREATE OR REPLACE RULE log_builds AS ON UPDATE TO builder
--    WHERE ( ( OLD.current IS NULL AND NEW.current IS NOT NULL)
--            OR NEW.current <> OLD.current )
--    DO ALSO SELECT * FROM update_build_log(NEW.current, NEW.platform, NEW.name);

CREATE OR REPLACE FUNCTION update_modification_time()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
   NEW.modtime = now(); 
   RETURN NEW;
END;
$$;

-- Trigger: builder_change
--
-- Every time a builder entry changes the modification time is updated.

CREATE TRIGGER builder_change BEFORE UPDATE
    ON builder FOR EACH ROW EXECUTE PROCEDURE 
    update_modification_time();

-- Trigger: job_change
--
-- Every time a job entry changes the modification time is updated.

CREATE TRIGGER job_change BEFORE UPDATE
    ON job FOR EACH ROW EXECUTE PROCEDURE 
    update_modification_time();

-- Trigger: task_change
--
-- Every time a task entry changes the modification time is updated.

CREATE TRIGGER task_change BEFORE UPDATE
    ON task FOR EACH ROW EXECUTE PROCEDURE 
    update_modification_time();

-- Big function for updating the job status whenever a task status changes

CREATE OR REPLACE FUNCTION update_job_status()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
   total_count      INTEGER := 0;
   fail_count       INTEGER := 0;
   success_count    INTEGER := 0;
   cancel_count     INTEGER := 0;
   task_id          INTEGER := NEW.id;
   job_id           INTEGER;
   job_status_name  VARCHAR(20) := NULL;
BEGIN

   SELECT job INTO job_id
       FROM task
       WHERE id = task_id
       LIMIT 1;

   IF NOT FOUND THEN
     RAISE NOTICE 'Could not find a job for task %', task_id;
     RETURN NEW;
   END IF;

   -- take update lock on relevant job row here

   SELECT COUNT(t.id) INTO total_count
       FROM task AS t
       WHERE t.job = job_id;

   SELECT COUNT(t.id) INTO fail_count
       FROM task AS t
       JOIN task_status AS s ON t.status = s.id
       WHERE t.job = job_id AND s.name = 'fail';

   SELECT COUNT(t.id) INTO success_count
       FROM task AS t
       JOIN task_status AS s ON t.status = s.id
       WHERE t.job = job_id AND s.name = 'success';

   SELECT COUNT(t.id) INTO cancel_count
       FROM task AS t
       JOIN task_status AS s ON t.status = s.id
       WHERE t.job = job_id AND s.name = 'cancelled';

   IF total_count > 0 THEN

     IF fail_count > 0 THEN

       IF fail_count = total_count THEN
         job_status_name := 'fail';
       ELSE
         job_status_name := 'partial fail';
       END IF;

     ELSIF success_count > 0 THEN

       IF success_count = total_count THEN
         job_status_name := 'success';
       ELSE
         job_status_name := 'partial success';
       END IF;

     ELSIF cancel_count = total_count THEN
         job_status_name := 'cancelled';
     END IF;

     IF job_status_name IS NOT NULL THEN

       UPDATE job SET status = 
         ( SELECT id FROM job_status WHERE name = job_status_name LIMIT 1)
         WHERE id = job_id;

     END IF;

   END IF;

   RETURN NEW;
END;
$$;

-- Trigger: task_status_change
--
-- Update the status for the job entry whenever a task is updated.

CREATE TRIGGER task_status_change AFTER UPDATE
    ON task FOR EACH ROW EXECUTE PROCEDURE 
    update_job_status(id);

-------------------------------------------------------------------------------
-- ACLs
--

-- Role: pkgforge_incoming
--
-- This role is used by the daemon which processes the incoming jobs
-- queue.
--
-- It needs to be able to:
--      add new jobs
--      update job status
--      add new tasks

GRANT SELECT                          ON builder     TO pkgforge_incoming;
GRANT SELECT,INSERT,UPDATE(status)    ON job         TO pkgforge_incoming;
GRANT SELECT,UPDATE                   ON job_id_seq  TO pkgforge_incoming;
GRANT SELECT                          ON job_status  TO pkgforge_incoming;
GRANT SELECT                          ON platform    TO pkgforge_incoming;
GRANT SELECT                          ON task_status TO pkgforge_incoming;
GRANT SELECT,INSERT                   ON task        TO pkgforge_incoming;
GRANT SELECT,UPDATE                   ON task_id_seq TO pkgforge_incoming;

-- Role: pkgforge_builder
--
-- This role is used by the build daemons.
--
-- It needs to be able to:
--      update the status (and modtime) of jobs
--      update the current job (and modtime) for a build daemon
--      insert entries into the build logs

GRANT SELECT,UPDATE(current,modtime)  ON builder     TO pkgforge_builder;
GRANT SELECT,UPDATE(status,modtime)   ON job         TO pkgforge_builder;
GRANT SELECT                          ON job_status  TO pkgforge_builder;
GRANT SELECT                          ON platform    TO pkgforge_builder;
GRANT SELECT                          ON task_status TO pkgforge_builder;
GRANT SELECT,UPDATE(status,modtime)   ON task        TO pkgforge_builder;
GRANT INSERT                          ON build_log   TO pkgforge_builder;
GRANT SELECT,UPDATE                   ON build_log_id_seq TO pkgforge_builder;

-- Role: pkgforge_web
--
-- This role is used by the web interface. Currently it only requires
-- read access to the database. That might change in the future.

GRANT SELECT                          ON build_log   TO pkgforge_web;
GRANT SELECT                          ON builder     TO pkgforge_web;
GRANT SELECT                          ON job         TO pkgforge_web;
GRANT SELECT                          ON job_status  TO pkgforge_web;
GRANT SELECT                          ON platform    TO pkgforge_web;
GRANT SELECT                          ON task        TO pkgforge_web;
GRANT SELECT                          ON task_status TO pkgforge_web;

COMMIT;
