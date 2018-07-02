-- 
-- Created by SQL::Translator::Producer::PostgreSQL
-- Created on Wed May 16 10:10:58 2018
-- 
;
--
-- Table: prf_owner_type
--
CREATE TABLE "prf_owner_type" (
  "prf_owner_type_id" serial NOT NULL,
  "owner_table" character varying NOT NULL,
  "owner_resultset" character varying NOT NULL,
  PRIMARY KEY ("prf_owner_type_id"),
  CONSTRAINT "prf_owner_type__resultset" UNIQUE ("owner_resultset"),
  CONSTRAINT "prf_owner_type__table" UNIQUE ("owner_table")
);

;
--
-- Table: prf_defaults
--
CREATE TABLE "prf_defaults" (
  "prf_owner_type_id" integer NOT NULL,
  "name" character varying NOT NULL,
  "default_value" character varying NOT NULL,
  "data_type" character varying,
  "comment" character varying,
  "required" boolean DEFAULT '0',
  "active" boolean DEFAULT '1',
  "hidden" boolean,
  "gdpr_erasable" boolean,
  "audit" boolean,
  "display_on_search" boolean,
  "searchable" boolean DEFAULT '1' NOT NULL,
  "unique_field" boolean,
  "ajax_validate" boolean,
  "display_order" integer DEFAULT 1 NOT NULL,
  "confirmation_required" boolean,
  "encrypted" boolean,
  "display_mask" character varying DEFAULT '(.*)' NOT NULL,
  "mask_char" character varying DEFAULT '*' NOT NULL,
  PRIMARY KEY ("prf_owner_type_id", "name")
);
CREATE INDEX "prf_defaults_idx_prf_owner_type_id" on "prf_defaults" ("prf_owner_type_id");

;
--
-- Table: prf_owners
--
CREATE TABLE "prf_owners" (
  "prf_owner_id" integer NOT NULL,
  "prf_owner_type_id" integer NOT NULL,
  PRIMARY KEY ("prf_owner_id", "prf_owner_type_id")
);
CREATE INDEX "prf_owners_idx_prf_owner_type_id" on "prf_owners" ("prf_owner_type_id");

;
--
-- Table: prf_default_values
--
CREATE TABLE "prf_default_values" (
  "id" serial NOT NULL,
  "value" text,
  "prf_owner_type_id" integer NOT NULL,
  "name" character varying NOT NULL,
  "display_order" integer DEFAULT 1 NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "prf_default_values_idx_prf_owner_type_id_name" on "prf_default_values" ("prf_owner_type_id", "name");

;
--
-- Table: prf_preferences
--
CREATE TABLE "prf_preferences" (
  "prf_preference_id" serial NOT NULL,
  "prf_owner_id" integer NOT NULL,
  "prf_owner_type_id" integer NOT NULL,
  "name" character varying NOT NULL,
  "value" character varying,
  PRIMARY KEY ("prf_preference_id"),
  CONSTRAINT "prf_preferences_prf_preference_id_prf_owner_type_id_name" UNIQUE ("prf_preference_id", "prf_owner_type_id", "name")
);
CREATE INDEX "prf_preferences_idx_prf_owner_id_prf_owner_type_id" on "prf_preferences" ("prf_owner_id", "prf_owner_type_id");

;
--
-- Table: prf_unique_vals
--
CREATE TABLE "prf_unique_vals" (
  "id" serial NOT NULL,
  "value_id" integer NOT NULL,
  "value" text,
  "prf_owner_type_id" integer NOT NULL,
  "name" character varying NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "prf_unique_vals_value_id_prf_owner_type_id_name" UNIQUE ("value_id", "prf_owner_type_id", "name"),
  CONSTRAINT "prf_unique_vals_value_prf_owner_type_id_name" UNIQUE ("value", "prf_owner_type_id", "name")
);
CREATE INDEX "prf_unique_vals_idx_prf_owner_type_id_name" on "prf_unique_vals" ("prf_owner_type_id", "name");
CREATE INDEX "prf_unique_vals_idx_value_id_prf_owner_type_id_name" on "prf_unique_vals" ("value_id", "prf_owner_type_id", "name");

;
--
-- Foreign Key Definitions
--

;
ALTER TABLE "prf_defaults" ADD CONSTRAINT "prf_defaults_fk_prf_owner_type_id" FOREIGN KEY ("prf_owner_type_id")
  REFERENCES "prf_owner_type" ("prf_owner_type_id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "prf_owners" ADD CONSTRAINT "prf_owners_fk_prf_owner_type_id" FOREIGN KEY ("prf_owner_type_id")
  REFERENCES "prf_owner_type" ("prf_owner_type_id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "prf_default_values" ADD CONSTRAINT "prf_default_values_fk_prf_owner_type_id_name" FOREIGN KEY ("prf_owner_type_id", "name")
  REFERENCES "prf_defaults" ("prf_owner_type_id", "name") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "prf_preferences" ADD CONSTRAINT "prf_preferences_fk_prf_owner_id_prf_owner_type_id" FOREIGN KEY ("prf_owner_id", "prf_owner_type_id")
  REFERENCES "prf_owners" ("prf_owner_id", "prf_owner_type_id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "prf_unique_vals" ADD CONSTRAINT "prf_unique_vals_fk_prf_owner_type_id_name" FOREIGN KEY ("prf_owner_type_id", "name")
  REFERENCES "prf_defaults" ("prf_owner_type_id", "name") DEFERRABLE;

;
ALTER TABLE "prf_unique_vals" ADD CONSTRAINT "prf_unique_vals_fk_value_id_prf_owner_type_id_name" FOREIGN KEY ("value_id", "prf_owner_type_id", "name")
  REFERENCES "prf_preferences" ("prf_preference_id", "prf_owner_type_id", "name") ON DELETE CASCADE DEFERRABLE;

;
