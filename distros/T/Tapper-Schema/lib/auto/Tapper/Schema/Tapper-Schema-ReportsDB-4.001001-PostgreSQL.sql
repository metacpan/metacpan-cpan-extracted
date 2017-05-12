-- 
-- Created by SQL::Translator::Producer::PostgreSQL
-- Created on Mon Sep 24 13:07:00 2012
-- 
--
-- Table: notification_event.
--
DROP TABLE "notification_event" CASCADE;
CREATE TABLE "notification_event" (
  "id" serial NOT NULL,
  "message" character varying(255),
  "type" character varying(255),
  "created_at" timestamp DEFAULT CURRENT_TIMESTAMP,
  "updated_at" timestamp,
  PRIMARY KEY ("id")
);

--
-- Table: owner.
--
DROP TABLE "owner" CASCADE;
CREATE TABLE "owner" (
  "id" serial NOT NULL,
  "name" character varying(255) NOT NULL,
  "login" character varying(255) NOT NULL,
  "password" character varying(255),
  PRIMARY KEY ("id"),
  CONSTRAINT "unique_login" UNIQUE ("login")
);

--
-- Table: reportgrouptestrunstats.
--
DROP TABLE "reportgrouptestrunstats" CASCADE;
CREATE TABLE "reportgrouptestrunstats" (
  "testrun_id" bigint NOT NULL,
  "total" integer,
  "failed" integer,
  "passed" integer,
  "parse_errors" integer,
  "skipped" integer,
  "todo" integer,
  "todo_passed" integer,
  "wait" integer,
  "success_ratio" character varying(20),
  PRIMARY KEY ("testrun_id")
);

--
-- Table: reportsection.
--
DROP TABLE "reportsection" CASCADE;
CREATE TABLE "reportsection" (
  "id" serial NOT NULL,
  "report_id" bigint NOT NULL,
  "succession" integer,
  "name" character varying(255),
  "osname" character varying(255),
  "uname" character varying(255),
  "flags" character varying(255),
  "changeset" character varying(255),
  "kernel" character varying(255),
  "description" character varying(255),
  "language_description" text,
  "cpuinfo" text,
  "bios" text,
  "ram" character varying(50),
  "uptime" character varying(50),
  "lspci" text,
  "lsusb" text,
  "ticket_url" character varying(255),
  "wiki_url" character varying(255),
  "planning_id" character varying(255),
  "moreinfo_url" character varying(255),
  "tags" character varying(255),
  "xen_changeset" character varying(255),
  "xen_hvbits" character varying(10),
  "xen_dom0_kernel" text,
  "xen_base_os_description" text,
  "xen_guest_description" text,
  "xen_guest_flags" character varying(255),
  "xen_version" character varying(255),
  "xen_guest_test" character varying(255),
  "xen_guest_start" character varying(255),
  "kvm_kernel" text,
  "kvm_base_os_description" text,
  "kvm_guest_description" text,
  "kvm_module_version" character varying(255),
  "kvm_userspace_version" character varying(255),
  "kvm_guest_flags" character varying(255),
  "kvm_guest_test" character varying(255),
  "kvm_guest_start" character varying(255),
  "simnow_svn_version" character varying(255),
  "simnow_version" character varying(255),
  "simnow_svn_repository" character varying(255),
  "simnow_device_interface_version" character varying(255),
  "simnow_bsd_file" character varying(255),
  "simnow_image_file" character varying(255),
  PRIMARY KEY ("id")
);

--
-- Table: suite.
--
DROP TABLE "suite" CASCADE;
CREATE TABLE "suite" (
  "id" serial NOT NULL,
  "name" character varying(255) NOT NULL,
  "type" character varying(50) NOT NULL,
  "description" text NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "suite_idx_name" on "suite" ("name");

--
-- Table: contact.
--
DROP TABLE "contact" CASCADE;
CREATE TABLE "contact" (
  "id" serial NOT NULL,
  "owner_id" bigint NOT NULL,
  "address" character varying(255) NOT NULL,
  "protocol" character varying(255) NOT NULL,
  "created_at" timestamp DEFAULT CURRENT_TIMESTAMP,
  "updated_at" timestamp,
  PRIMARY KEY ("id")
);
CREATE INDEX "contact_idx_owner_id" on "contact" ("owner_id");

--
-- Table: notification.
--
DROP TABLE "notification" CASCADE;
CREATE TABLE "notification" (
  "id" serial NOT NULL,
  "owner_id" bigint,
  "persist" smallint,
  "event" character varying(255) NOT NULL,
  "filter" text NOT NULL,
  "comment" character varying(255),
  "created_at" timestamp DEFAULT CURRENT_TIMESTAMP,
  "updated_at" timestamp,
  PRIMARY KEY ("id")
);
CREATE INDEX "notification_idx_owner_id" on "notification" ("owner_id");

--
-- Table: report.
--
DROP TABLE "report" CASCADE;
CREATE TABLE "report" (
  "id" serial NOT NULL,
  "suite_id" bigint,
  "suite_version" character varying(11),
  "reportername" character varying(100) DEFAULT '',
  "peeraddr" character varying(20) DEFAULT '',
  "peerport" character varying(20) DEFAULT '',
  "peerhost" character varying(255) DEFAULT '',
  "successgrade" character varying(10) DEFAULT '',
  "reviewed_successgrade" character varying(10) DEFAULT '',
  "total" integer,
  "failed" integer,
  "parse_errors" integer,
  "passed" integer,
  "skipped" integer,
  "todo" integer,
  "todo_passed" integer,
  "wait" integer,
  "exit" integer,
  "success_ratio" character varying(20),
  "starttime_test_program" timestamp,
  "endtime_test_program" timestamp,
  "machine_name" character varying(50) DEFAULT '',
  "machine_description" text DEFAULT '',
  "created_at" timestamp NOT NULL,
  "updated_at" timestamp NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "report_idx_suite_id" on "report" ("suite_id");
CREATE INDEX "report_idx_machine_name" on "report" ("machine_name");

--
-- Table: reportfile.
--
DROP TABLE "reportfile" CASCADE;
CREATE TABLE "reportfile" (
  "id" serial NOT NULL,
  "report_id" bigint NOT NULL,
  "filename" character varying(255) DEFAULT '',
  "contenttype" character varying(255) DEFAULT '',
  "filecontent" bytea DEFAULT '' NOT NULL,
  "is_compressed" integer DEFAULT 0 NOT NULL,
  "created_at" timestamp NOT NULL,
  "updated_at" timestamp NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "reportfile_idx_report_id" on "reportfile" ("report_id");

--
-- Table: reportgrouparbitrary.
--
DROP TABLE "reportgrouparbitrary" CASCADE;
CREATE TABLE "reportgrouparbitrary" (
  "arbitrary_id" character varying(255) NOT NULL,
  "report_id" bigint NOT NULL,
  "primaryreport" bigint,
  "owner" character varying(255),
  PRIMARY KEY ("arbitrary_id", "report_id")
);
CREATE INDEX "reportgrouparbitrary_idx_report_id" on "reportgrouparbitrary" ("report_id");

--
-- Table: reportgrouptestrun.
--
DROP TABLE "reportgrouptestrun" CASCADE;
CREATE TABLE "reportgrouptestrun" (
  "testrun_id" bigint NOT NULL,
  "report_id" bigint NOT NULL,
  "primaryreport" bigint,
  "owner" character varying(255),
  PRIMARY KEY ("testrun_id", "report_id")
);
CREATE INDEX "reportgrouptestrun_idx_report_id" on "reportgrouptestrun" ("report_id");

--
-- Table: reporttopic.
--
DROP TABLE "reporttopic" CASCADE;
CREATE TABLE "reporttopic" (
  "id" serial NOT NULL,
  "report_id" bigint NOT NULL,
  "name" character varying(50) DEFAULT '',
  "details" text DEFAULT '' NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "reporttopic_idx_report_id" on "reporttopic" ("report_id");

--
-- Table: tap.
--
DROP TABLE "tap" CASCADE;
CREATE TABLE "tap" (
  "id" serial NOT NULL,
  "report_id" bigint NOT NULL,
  "tap" bytea DEFAULT '' NOT NULL,
  "tap_is_archive" bigint,
  "tapdom" bytea DEFAULT '',
  "created_at" timestamp NOT NULL,
  "updated_at" timestamp NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "tap_idx_report_id" on "tap" ("report_id");

--
-- Table: reportcomment.
--
DROP TABLE "reportcomment" CASCADE;
CREATE TABLE "reportcomment" (
  "id" serial NOT NULL,
  "report_id" bigint NOT NULL,
  "owner_id" bigint,
  "succession" integer,
  "comment" text DEFAULT '' NOT NULL,
  "created_at" timestamp NOT NULL,
  "updated_at" timestamp NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "reportcomment_idx_owner_id" on "reportcomment" ("owner_id");
CREATE INDEX "reportcomment_idx_report_id" on "reportcomment" ("report_id");

--
-- View: "view_testrun_overview_reports"
--
DROP VIEW "view_testrun_overview_reports";
CREATE VIEW "view_testrun_overview_reports" ( "rgt_testrun_id", "rgts_success_ratio", "primary_report_id" ) AS
    select rgts.testrun_id    as rgt_testrun_id,        max(rgt.report_id) as primary_report_id,        rgts.success_ratio as rgts_success_ratio from reportgrouptestrun rgt, reportgrouptestrunstats rgts where rgt.testrun_id=rgts.testrun_id group by rgt.testrun_id
;

--
-- View: "view_testrun_overview"
--
DROP VIEW "view_testrun_overview";
CREATE VIEW "view_testrun_overview" ( "rgt_testrun_id", "rgts_success_ratio", "primary_report_id", "machine_name", "created_at", "suite_id", "suite_name" ) AS
    select vtor.*,        r.machine_name,        r.created_at,        r.suite_id,        s.name as suite_name from view_testrun_overview_reports vtor,      report r,      suite s where vtor.primary_report_id=r.id and       r.suite_id=s.id
;

--
-- Foreign Key Definitions
--

ALTER TABLE "contact" ADD CONSTRAINT "contact_fk_owner_id" FOREIGN KEY ("owner_id")
  REFERENCES "owner" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

ALTER TABLE "notification" ADD CONSTRAINT "notification_fk_owner_id" FOREIGN KEY ("owner_id")
  REFERENCES "owner" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

ALTER TABLE "report" ADD CONSTRAINT "report_fk_suite_id" FOREIGN KEY ("suite_id")
  REFERENCES "suite" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

ALTER TABLE "reportfile" ADD CONSTRAINT "reportfile_fk_report_id" FOREIGN KEY ("report_id")
  REFERENCES "report" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

ALTER TABLE "reportgrouparbitrary" ADD CONSTRAINT "reportgrouparbitrary_fk_report_id" FOREIGN KEY ("report_id")
  REFERENCES "report" ("id") ON DELETE CASCADE DEFERRABLE;

ALTER TABLE "reportgrouptestrun" ADD CONSTRAINT "reportgrouptestrun_fk_report_id" FOREIGN KEY ("report_id")
  REFERENCES "report" ("id") ON DELETE CASCADE DEFERRABLE;

ALTER TABLE "reporttopic" ADD CONSTRAINT "reporttopic_fk_report_id" FOREIGN KEY ("report_id")
  REFERENCES "report" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

ALTER TABLE "tap" ADD CONSTRAINT "tap_fk_report_id" FOREIGN KEY ("report_id")
  REFERENCES "report" ("id") ON DELETE CASCADE DEFERRABLE;

ALTER TABLE "reportcomment" ADD CONSTRAINT "reportcomment_fk_owner_id" FOREIGN KEY ("owner_id")
  REFERENCES "owner" ("id") DEFERRABLE;

ALTER TABLE "reportcomment" ADD CONSTRAINT "reportcomment_fk_report_id" FOREIGN KEY ("report_id")
  REFERENCES "report" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

