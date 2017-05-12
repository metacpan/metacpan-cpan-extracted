-- Convert schema 'upgrades/Tapper-Schema-ReportsDB-2.010030-SQLite.sql' to 'upgrades/Tapper-Schema-ReportsDB-2.010031-SQLite.sql':;

BEGIN;

ALTER TABLE reportsection ADD COLUMN simnow_svn_version VARCHAR(255);

ALTER TABLE reportsection ADD COLUMN simnow_version VARCHAR(255);

ALTER TABLE reportsection ADD COLUMN simnow_svn_repository VARCHAR(255);

ALTER TABLE reportsection ADD COLUMN simnow_device_interface_version VARCHAR(255);

ALTER TABLE reportsection ADD COLUMN simnow_bsd_file VARCHAR(255);

ALTER TABLE reportsection ADD COLUMN simnow_image_file VARCHAR(255);


COMMIT;

