-- Convert schema '/opt/local/tp/OpusVL-Preferences/lib/auto/OpusVL/Preferences/Schema/sql/_source/deploy/1/001-auto.yml' to '/opt/local/tp/OpusVL-Preferences/lib/auto/OpusVL/Preferences/Schema/sql/_source/deploy/2/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE prf_defaults ALTER COLUMN display_mask DROP NOT NULL;

;
ALTER TABLE prf_defaults ALTER COLUMN mask_char DROP NOT NULL;

;

COMMIT;

