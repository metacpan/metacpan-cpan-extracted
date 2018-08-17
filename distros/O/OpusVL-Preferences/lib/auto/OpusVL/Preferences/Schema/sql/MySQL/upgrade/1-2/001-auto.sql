-- Convert schema '/opt/local/tp/OpusVL-Preferences/lib/auto/OpusVL/Preferences/Schema/sql/_source/deploy/1/001-auto.yml' to '/opt/local/tp/OpusVL-Preferences/lib/auto/OpusVL/Preferences/Schema/sql/_source/deploy/2/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE prf_defaults CHANGE COLUMN display_mask display_mask varchar(255) NULL DEFAULT '(.*)',
                         CHANGE COLUMN mask_char mask_char varchar(255) NULL DEFAULT '*';

;

COMMIT;

