-- Convert schema '/2home/ss5/local/projects/Tapper/src/Tapper-Schema/upgrades/Tapper-Schema-ReportsDB-2.010010-MySQL.sql' to '/2home/ss5/local/projects/Tapper/src/Tapper-Schema/upgrades/Tapper-Schema-ReportsDB-2.010011-MySQL.sql':

BEGIN;

ALTER TABLE reportcomment CHANGE COLUMN created_at created_at datetime NOT NULL,
                          CHANGE COLUMN updated_at updated_at datetime NOT NULL;
ALTER TABLE reportfile ADD COLUMN created_at datetime NOT NULL,
                       ADD COLUMN updated_at datetime NOT NULL;

COMMIT;
