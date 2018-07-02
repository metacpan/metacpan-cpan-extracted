-- 
-- Created by SQL::Translator::Producer::SQLite
-- Created on Wed May 16 10:10:58 2018
-- 

;
BEGIN TRANSACTION;
--
-- Table: prf_owner_type
--
CREATE TABLE prf_owner_type (
  prf_owner_type_id INTEGER PRIMARY KEY NOT NULL,
  owner_table varchar NOT NULL,
  owner_resultset varchar NOT NULL
);
CREATE UNIQUE INDEX prf_owner_type__resultset ON prf_owner_type (owner_resultset);
CREATE UNIQUE INDEX prf_owner_type__table ON prf_owner_type (owner_table);
--
-- Table: prf_defaults
--
CREATE TABLE prf_defaults (
  prf_owner_type_id integer NOT NULL,
  name varchar NOT NULL,
  default_value varchar NOT NULL,
  data_type varchar,
  comment varchar,
  required boolean DEFAULT 0,
  active boolean DEFAULT 1,
  hidden boolean,
  gdpr_erasable boolean,
  audit boolean,
  display_on_search boolean,
  searchable boolean NOT NULL DEFAULT 1,
  unique_field boolean,
  ajax_validate boolean,
  display_order int NOT NULL DEFAULT 1,
  confirmation_required boolean,
  encrypted boolean,
  display_mask varchar NOT NULL DEFAULT '(.*)',
  mask_char varchar NOT NULL DEFAULT '*',
  PRIMARY KEY (prf_owner_type_id, name),
  FOREIGN KEY (prf_owner_type_id) REFERENCES prf_owner_type(prf_owner_type_id) ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX prf_defaults_idx_prf_owner_type_id ON prf_defaults (prf_owner_type_id);
--
-- Table: prf_owners
--
CREATE TABLE prf_owners (
  prf_owner_id integer NOT NULL,
  prf_owner_type_id integer NOT NULL,
  PRIMARY KEY (prf_owner_id, prf_owner_type_id),
  FOREIGN KEY (prf_owner_type_id) REFERENCES prf_owner_type(prf_owner_type_id) ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX prf_owners_idx_prf_owner_type_id ON prf_owners (prf_owner_type_id);
--
-- Table: prf_default_values
--
CREATE TABLE prf_default_values (
  id INTEGER PRIMARY KEY NOT NULL,
  value text,
  prf_owner_type_id integer NOT NULL,
  name varchar NOT NULL,
  display_order int NOT NULL DEFAULT 1,
  FOREIGN KEY (prf_owner_type_id, name) REFERENCES prf_defaults(prf_owner_type_id, name) ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX prf_default_values_idx_prf_owner_type_id_name ON prf_default_values (prf_owner_type_id, name);
--
-- Table: prf_preferences
--
CREATE TABLE prf_preferences (
  prf_preference_id INTEGER PRIMARY KEY NOT NULL,
  prf_owner_id integer NOT NULL,
  prf_owner_type_id integer NOT NULL,
  name varchar NOT NULL,
  value varchar,
  FOREIGN KEY (prf_owner_id, prf_owner_type_id) REFERENCES prf_owners(prf_owner_id, prf_owner_type_id) ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX prf_preferences_idx_prf_owner_id_prf_owner_type_id ON prf_preferences (prf_owner_id, prf_owner_type_id);
CREATE UNIQUE INDEX prf_preferences_prf_preference_id_prf_owner_type_id_name ON prf_preferences (prf_preference_id, prf_owner_type_id, name);
--
-- Table: prf_unique_vals
--
CREATE TABLE prf_unique_vals (
  id INTEGER PRIMARY KEY NOT NULL,
  value_id integer NOT NULL,
  value text,
  prf_owner_type_id integer NOT NULL,
  name varchar NOT NULL,
  FOREIGN KEY (prf_owner_type_id, name) REFERENCES prf_defaults(prf_owner_type_id, name),
  FOREIGN KEY (value_id, prf_owner_type_id, name) REFERENCES prf_preferences(prf_preference_id, prf_owner_type_id, name) ON DELETE CASCADE
);
CREATE INDEX prf_unique_vals_idx_prf_owner_type_id_name ON prf_unique_vals (prf_owner_type_id, name);
CREATE INDEX prf_unique_vals_idx_value_id_prf_owner_type_id_name ON prf_unique_vals (value_id, prf_owner_type_id, name);
CREATE UNIQUE INDEX prf_unique_vals_value_id_prf_owner_type_id_name ON prf_unique_vals (value_id, prf_owner_type_id, name);
CREATE UNIQUE INDEX prf_unique_vals_value_prf_owner_type_id_name ON prf_unique_vals (value, prf_owner_type_id, name);
COMMIT;
