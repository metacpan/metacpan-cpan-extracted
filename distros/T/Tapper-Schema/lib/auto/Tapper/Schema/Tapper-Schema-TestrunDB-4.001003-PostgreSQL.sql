-- 
-- Created by SQL::Translator::Producer::PostgreSQL
-- Created on Fri Sep 28 15:39:36 2012
-- 
--
-- Table: host.
--
DROP TABLE "host" CASCADE;
CREATE TABLE "host" (
  "id" serial NOT NULL,
  "name" character varying(255) DEFAULT '',
  "comment" character varying(255) DEFAULT '',
  "free" smallint DEFAULT 0,
  "active" smallint DEFAULT 0,
  "is_deleted" smallint DEFAULT 0,
  "created_at" timestamp DEFAULT CURRENT_TIMESTAMP,
  "updated_at" timestamp,
  PRIMARY KEY ("id"),
  CONSTRAINT "constraint_name" UNIQUE ("name")
);

--
-- Table: owner.
--
DROP TABLE "owner" CASCADE;
CREATE TABLE "owner" (
  "id" serial NOT NULL,
  "name" character varying(255),
  "login" character varying(255) NOT NULL,
  "password" character varying(255),
  PRIMARY KEY ("id")
);

--
-- Table: precondition.
--
DROP TABLE "precondition" CASCADE;
CREATE TABLE "precondition" (
  "id" serial NOT NULL,
  "shortname" character varying(255) DEFAULT '' NOT NULL,
  "precondition" text,
  "timeout" integer,
  PRIMARY KEY ("id")
);

--
-- Table: preconditiontype.
--
DROP TABLE "preconditiontype" CASCADE;
CREATE TABLE "preconditiontype" (
  "name" character varying(20) NOT NULL,
  "description" text DEFAULT '' NOT NULL,
  PRIMARY KEY ("name")
);

--
-- Table: queue.
--
DROP TABLE "queue" CASCADE;
CREATE TABLE "queue" (
  "id" serial NOT NULL,
  "name" character varying(255) DEFAULT '',
  "priority" integer DEFAULT 0 NOT NULL,
  "runcount" integer DEFAULT 0 NOT NULL,
  "active" smallint DEFAULT 0,
  "is_deleted" smallint DEFAULT 0,
  "created_at" timestamp DEFAULT CURRENT_TIMESTAMP,
  "updated_at" timestamp,
  PRIMARY KEY ("id"),
  CONSTRAINT "unique_queue_name" UNIQUE ("name")
);

--
-- Table: scenario.
--
DROP TABLE "scenario" CASCADE;
CREATE TABLE "scenario" (
  "id" serial NOT NULL,
  "type" character varying(255) DEFAULT '' NOT NULL,
  PRIMARY KEY ("id")
);

--
-- Table: testplan_instance.
--
DROP TABLE "testplan_instance" CASCADE;
CREATE TABLE "testplan_instance" (
  "id" serial NOT NULL,
  "path" character varying(255) DEFAULT '',
  "name" character varying(255) DEFAULT '',
  "evaluated_testplan" text DEFAULT '',
  "created_at" timestamp DEFAULT CURRENT_TIMESTAMP,
  "updated_at" timestamp,
  PRIMARY KEY ("id")
);

--
-- Table: topic.
--
DROP TABLE "topic" CASCADE;
CREATE TABLE "topic" (
  "name" character varying(255) NOT NULL,
  "description" text DEFAULT '' NOT NULL,
  PRIMARY KEY ("name")
);

--
-- Table: host_feature.
--
DROP TABLE "host_feature" CASCADE;
CREATE TABLE "host_feature" (
  "id" serial NOT NULL,
  "host_id" integer NOT NULL,
  "entry" character varying(255) NOT NULL,
  "value" character varying(255) NOT NULL,
  "created_at" timestamp DEFAULT CURRENT_TIMESTAMP,
  "updated_at" timestamp,
  PRIMARY KEY ("id")
);
CREATE INDEX "host_feature_idx_host_id" on "host_feature" ("host_id");

--
-- Table: pre_precondition.
--
DROP TABLE "pre_precondition" CASCADE;
CREATE TABLE "pre_precondition" (
  "parent_precondition_id" bigint NOT NULL,
  "child_precondition_id" bigint NOT NULL,
  "succession" integer NOT NULL,
  PRIMARY KEY ("parent_precondition_id", "child_precondition_id")
);
CREATE INDEX "pre_precondition_idx_child_precondition_id" on "pre_precondition" ("child_precondition_id");
CREATE INDEX "pre_precondition_idx_parent_precondition_id" on "pre_precondition" ("parent_precondition_id");

--
-- Table: denied_host.
--
DROP TABLE "denied_host" CASCADE;
CREATE TABLE "denied_host" (
  "id" serial NOT NULL,
  "queue_id" bigint NOT NULL,
  "host_id" bigint NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "denied_host_idx_host_id" on "denied_host" ("host_id");
CREATE INDEX "denied_host_idx_queue_id" on "denied_host" ("queue_id");

--
-- Table: queue_host.
--
DROP TABLE "queue_host" CASCADE;
CREATE TABLE "queue_host" (
  "id" serial NOT NULL,
  "queue_id" bigint NOT NULL,
  "host_id" bigint NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "queue_host_idx_host_id" on "queue_host" ("host_id");
CREATE INDEX "queue_host_idx_queue_id" on "queue_host" ("queue_id");

--
-- Table: testrun.
--
DROP TABLE "testrun" CASCADE;
CREATE TABLE "testrun" (
  "id" serial NOT NULL,
  "shortname" character varying(255) DEFAULT '',
  "notes" text DEFAULT '',
  "topic_name" character varying(255) DEFAULT '' NOT NULL,
  "starttime_earliest" timestamp,
  "starttime_testrun" timestamp,
  "starttime_test_program" timestamp,
  "endtime_test_program" timestamp,
  "owner_id" bigint,
  "testplan_id" bigint,
  "wait_after_tests" smallint DEFAULT 0,
  "rerun_on_error" bigint DEFAULT 0,
  "created_at" timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
  "updated_at" timestamp,
  PRIMARY KEY ("id")
);
CREATE INDEX "testrun_idx_owner_id" on "testrun" ("owner_id");
CREATE INDEX "testrun_idx_testplan_id" on "testrun" ("testplan_id");

--
-- Table: message.
--
DROP TABLE "message" CASCADE;
CREATE TABLE "message" (
  "id" serial NOT NULL,
  "testrun_id" bigint,
  "message" character varying(65000),
  "type" character varying(255),
  "created_at" timestamp DEFAULT CURRENT_TIMESTAMP,
  "updated_at" timestamp,
  PRIMARY KEY ("id")
);
CREATE INDEX "message_idx_testrun_id" on "message" ("testrun_id");

--
-- Table: state.
--
DROP TABLE "state" CASCADE;
CREATE TABLE "state" (
  "id" serial NOT NULL,
  "testrun_id" bigint NOT NULL,
  "state" character varying(65000),
  "created_at" timestamp DEFAULT CURRENT_TIMESTAMP,
  "updated_at" timestamp,
  PRIMARY KEY ("id"),
  CONSTRAINT "unique_testrun_id" UNIQUE ("testrun_id")
);
CREATE INDEX "state_idx_testrun_id" on "state" ("testrun_id");

--
-- Table: testrun_requested_feature.
--
DROP TABLE "testrun_requested_feature" CASCADE;
CREATE TABLE "testrun_requested_feature" (
  "id" serial NOT NULL,
  "testrun_id" bigint NOT NULL,
  "feature" character varying(255) DEFAULT '',
  PRIMARY KEY ("id")
);
CREATE INDEX "testrun_requested_feature_idx_testrun_id" on "testrun_requested_feature" ("testrun_id");

--
-- Table: scenario_element.
--
DROP TABLE "scenario_element" CASCADE;
CREATE TABLE "scenario_element" (
  "id" serial NOT NULL,
  "testrun_id" bigint NOT NULL,
  "scenario_id" bigint NOT NULL,
  "is_fitted" smallint DEFAULT 0 NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "scenario_element_idx_scenario_id" on "scenario_element" ("scenario_id");
CREATE INDEX "scenario_element_idx_testrun_id" on "scenario_element" ("testrun_id");

--
-- Table: testrun_precondition.
--
DROP TABLE "testrun_precondition" CASCADE;
CREATE TABLE "testrun_precondition" (
  "testrun_id" bigint NOT NULL,
  "precondition_id" bigint NOT NULL,
  "succession" integer,
  PRIMARY KEY ("testrun_id", "precondition_id")
);
CREATE INDEX "testrun_precondition_idx_precondition_id" on "testrun_precondition" ("precondition_id");
CREATE INDEX "testrun_precondition_idx_testrun_id" on "testrun_precondition" ("testrun_id");

--
-- Table: testrun_requested_host.
--
DROP TABLE "testrun_requested_host" CASCADE;
CREATE TABLE "testrun_requested_host" (
  "id" serial NOT NULL,
  "testrun_id" bigint NOT NULL,
  "host_id" bigint NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "testrun_requested_host_idx_host_id" on "testrun_requested_host" ("host_id");
CREATE INDEX "testrun_requested_host_idx_testrun_id" on "testrun_requested_host" ("testrun_id");

--
-- Table: testrun_scheduling.
--
DROP TABLE "testrun_scheduling" CASCADE;
CREATE TABLE "testrun_scheduling" (
  "id" serial NOT NULL,
  "testrun_id" bigint NOT NULL,
  "queue_id" bigint DEFAULT 0,
  "host_id" bigint,
  "prioqueue_seq" bigint,
  "status" character varying(255) DEFAULT 'prepare',
  "auto_rerun" smallint DEFAULT 0,
  "created_at" timestamp DEFAULT CURRENT_TIMESTAMP,
  "updated_at" timestamp,
  PRIMARY KEY ("id")
);
CREATE INDEX "testrun_scheduling_idx_host_id" on "testrun_scheduling" ("host_id");
CREATE INDEX "testrun_scheduling_idx_queue_id" on "testrun_scheduling" ("queue_id");
CREATE INDEX "testrun_scheduling_idx_testrun_id" on "testrun_scheduling" ("testrun_id");

--
-- Foreign Key Definitions
--

ALTER TABLE "host_feature" ADD CONSTRAINT "host_feature_fk_host_id" FOREIGN KEY ("host_id")
  REFERENCES "host" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

ALTER TABLE "pre_precondition" ADD CONSTRAINT "pre_precondition_fk_child_precondition_id" FOREIGN KEY ("child_precondition_id")
  REFERENCES "precondition" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

ALTER TABLE "pre_precondition" ADD CONSTRAINT "pre_precondition_fk_parent_precondition_id" FOREIGN KEY ("parent_precondition_id")
  REFERENCES "precondition" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

ALTER TABLE "denied_host" ADD CONSTRAINT "denied_host_fk_host_id" FOREIGN KEY ("host_id")
  REFERENCES "host" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

ALTER TABLE "denied_host" ADD CONSTRAINT "denied_host_fk_queue_id" FOREIGN KEY ("queue_id")
  REFERENCES "queue" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

ALTER TABLE "queue_host" ADD CONSTRAINT "queue_host_fk_host_id" FOREIGN KEY ("host_id")
  REFERENCES "host" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

ALTER TABLE "queue_host" ADD CONSTRAINT "queue_host_fk_queue_id" FOREIGN KEY ("queue_id")
  REFERENCES "queue" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

ALTER TABLE "testrun" ADD CONSTRAINT "testrun_fk_owner_id" FOREIGN KEY ("owner_id")
  REFERENCES "owner" ("id") DEFERRABLE;

ALTER TABLE "testrun" ADD CONSTRAINT "testrun_fk_testplan_id" FOREIGN KEY ("testplan_id")
  REFERENCES "testplan_instance" ("id") ON UPDATE CASCADE DEFERRABLE;

ALTER TABLE "message" ADD CONSTRAINT "message_fk_testrun_id" FOREIGN KEY ("testrun_id")
  REFERENCES "testrun" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

ALTER TABLE "state" ADD CONSTRAINT "state_fk_testrun_id" FOREIGN KEY ("testrun_id")
  REFERENCES "testrun" ("id") ON DELETE CASCADE DEFERRABLE;

ALTER TABLE "testrun_requested_feature" ADD CONSTRAINT "testrun_requested_feature_fk_testrun_id" FOREIGN KEY ("testrun_id")
  REFERENCES "testrun" ("id") DEFERRABLE;

ALTER TABLE "scenario_element" ADD CONSTRAINT "scenario_element_fk_scenario_id" FOREIGN KEY ("scenario_id")
  REFERENCES "scenario" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

ALTER TABLE "scenario_element" ADD CONSTRAINT "scenario_element_fk_testrun_id" FOREIGN KEY ("testrun_id")
  REFERENCES "testrun" ("id") ON DELETE CASCADE DEFERRABLE;

ALTER TABLE "testrun_precondition" ADD CONSTRAINT "testrun_precondition_fk_precondition_id" FOREIGN KEY ("precondition_id")
  REFERENCES "precondition" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

ALTER TABLE "testrun_precondition" ADD CONSTRAINT "testrun_precondition_fk_testrun_id" FOREIGN KEY ("testrun_id")
  REFERENCES "testrun" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

ALTER TABLE "testrun_requested_host" ADD CONSTRAINT "testrun_requested_host_fk_host_id" FOREIGN KEY ("host_id")
  REFERENCES "host" ("id") DEFERRABLE;

ALTER TABLE "testrun_requested_host" ADD CONSTRAINT "testrun_requested_host_fk_testrun_id" FOREIGN KEY ("testrun_id")
  REFERENCES "testrun" ("id") DEFERRABLE;

ALTER TABLE "testrun_scheduling" ADD CONSTRAINT "testrun_scheduling_fk_host_id" FOREIGN KEY ("host_id")
  REFERENCES "host" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

ALTER TABLE "testrun_scheduling" ADD CONSTRAINT "testrun_scheduling_fk_queue_id" FOREIGN KEY ("queue_id")
  REFERENCES "queue" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

ALTER TABLE "testrun_scheduling" ADD CONSTRAINT "testrun_scheduling_fk_testrun_id" FOREIGN KEY ("testrun_id")
  REFERENCES "testrun" ("id") ON DELETE CASCADE DEFERRABLE;

