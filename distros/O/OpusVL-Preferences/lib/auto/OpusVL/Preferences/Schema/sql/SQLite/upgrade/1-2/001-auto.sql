-- Convert schema '/opt/local/tp/OpusVL-Preferences/lib/auto/OpusVL/Preferences/Schema/sql/_source/deploy/1/001-auto.yml' to '/opt/local/tp/OpusVL-Preferences/lib/auto/OpusVL/Preferences/Schema/sql/_source/deploy/2/001-auto.yml':;

;
BEGIN;

;
CREATE TEMPORARY TABLE prf_defaults_temp_alter (
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
  display_mask varchar DEFAULT '(.*)',
  mask_char varchar DEFAULT '*',
  PRIMARY KEY (prf_owner_type_id, name),
  FOREIGN KEY (prf_owner_type_id) REFERENCES prf_owner_type(prf_owner_type_id) ON DELETE CASCADE ON UPDATE CASCADE
);

;
INSERT INTO prf_defaults_temp_alter( prf_owner_type_id, name, default_value, data_type, comment, required, active, hidden, gdpr_erasable, audit, display_on_search, searchable, unique_field, ajax_validate, display_order, confirmation_required, encrypted, display_mask, mask_char) SELECT prf_owner_type_id, name, default_value, data_type, comment, required, active, hidden, gdpr_erasable, audit, display_on_search, searchable, unique_field, ajax_validate, display_order, confirmation_required, encrypted, display_mask, mask_char FROM prf_defaults;

;
DROP TABLE prf_defaults;

;
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
  display_mask varchar DEFAULT '(.*)',
  mask_char varchar DEFAULT '*',
  PRIMARY KEY (prf_owner_type_id, name),
  FOREIGN KEY (prf_owner_type_id) REFERENCES prf_owner_type(prf_owner_type_id) ON DELETE CASCADE ON UPDATE CASCADE
);

;
CREATE INDEX prf_defaults_idx_prf_owner_00 ON prf_defaults (prf_owner_type_id);

;
INSERT INTO prf_defaults SELECT prf_owner_type_id, name, default_value, data_type, comment, required, active, hidden, gdpr_erasable, audit, display_on_search, searchable, unique_field, ajax_validate, display_order, confirmation_required, encrypted, display_mask, mask_char FROM prf_defaults_temp_alter;

;
DROP TABLE prf_defaults_temp_alter;

;

COMMIT;

