BEGIN;

-- Downgrade script from version 20 to 21
ALTER TABLE `song`
    DROP COLUMN `artist_id`,
    DROP INDEX `idx_artist_id`;

-- Remove the schema version stored by DBIx::Class::Schema::Versioned
DELETE FROM `dbix_class_schema_versions` WHERE version = 21 LIMIT 1;

COMMIT;
