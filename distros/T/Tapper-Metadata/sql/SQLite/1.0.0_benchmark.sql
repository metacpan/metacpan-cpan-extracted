DROP TABLE IF EXISTS `bench_backup_additional_relations`;
DROP TABLE IF EXISTS `bench_backup_values`;
DROP TABLE IF EXISTS `bench_additional_relations`;
DROP TABLE IF EXISTS `bench_additional_type_relations`;
DROP TABLE IF EXISTS `bench_additional_values`;
DROP TABLE IF EXISTS `bench_additional_types`;
DROP TABLE IF EXISTS `bench_values`;
DROP TABLE IF EXISTS `benchs`;
DROP TABLE IF EXISTS `bench_units`;
DROP TABLE IF EXISTS `bench_suites`;
DROP TABLE IF EXISTS `bench_subsume_types`;

CREATE  TABLE `bench_suites` (
  `bench_suite_id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `bench_suite` VARCHAR(255) NOT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE UNIQUE INDEX IF NOT EXISTS `ux_bench_suites_01` 
ON `bench_suites`(`bench_suite_id`);

CREATE TABLE `bench_subsume_types` (
  `bench_subsume_type_id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `bench_subsume_type` VARCHAR(32) NOT NULL,
  `bench_subsume_type_rank` TINYINT(3) NOT NULL,
  `datetime_strftime_pattern` VARCHAR(32) NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE UNIQUE INDEX IF NOT EXISTS `ux_bench_subsume_types_01`
ON `bench_subsume_types`(`bench_subsume_type`);

CREATE TABLE `bench_units` (
  `bench_unit_id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `bench_unit` VARCHAR(128) NOT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE UNIQUE INDEX IF NOT EXISTS `ux_bench_units_01`
ON `bench_units`(`bench_unit`);

CREATE TABLE `benchs` (
  `bench_id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `bench_unit_id` TINYINT(3) NULL,
  `bench_suite_id` INT(10) NULL,
  `bench` VARCHAR(512) NOT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT `fk_benchs_01`
    FOREIGN KEY (`bench_unit_id`)
    REFERENCES `bench_units` (`bench_unit_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_benchs_02`
    FOREIGN KEY (`bench_suite_id` )
    REFERENCES `bench_suites` (`bench_suite_id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
);
CREATE UNIQUE INDEX IF NOT EXISTS `ux_benchs_01` ON `benchs`(`bench`);
CREATE INDEX IF NOT EXISTS `fk_benchs_01` ON `benchs`(`bench_unit_id`);
CREATE INDEX IF NOT EXISTS `fk_benchs_02` ON `benchs`(`bench_suite_id`);

CREATE TABLE `bench_values` (
  `bench_value_id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `bench_id` INT(10) NOT NULL,
  `bench_subsume_type_id` TINYINT(3) NOT NULL,
  `bench_value` FLOAT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT `fk_bench_values_01`
    FOREIGN KEY (`bench_id`)
    REFERENCES `benchs` (`bench_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_bench_values_02`
    FOREIGN KEY (`bench_subsume_type_id`)
    REFERENCES `bench_subsume_types` (`bench_subsume_type_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
);
CREATE INDEX IF NOT EXISTS `fk_bench_values_01`
ON `bench_values`(`bench_id`);
CREATE INDEX IF NOT EXISTS `fk_bench_values_02`
ON `bench_values`(`bench_subsume_type_id`);

CREATE TABLE `bench_additional_types` (
  `bench_additional_type_id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `bench_additional_type` VARCHAR(512) NOT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE UNIQUE INDEX IF NOT EXISTS `ux_bench_additional_types_01`
ON `bench_additional_types`(`bench_additional_type`);

CREATE TABLE `bench_additional_values` (
  `bench_additional_value_id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `bench_additional_type_id` SMALLINT(5) NOT NULL,
  `bench_additional_value` VARCHAR(512) NOT NULL,
  CONSTRAINT `fk_bench_additional_values_01`
    FOREIGN KEY (`bench_additional_type_id`)
    REFERENCES `bench_additional_types` (`bench_additional_type_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
);
CREATE UNIQUE INDEX IF NOT EXISTS `ux_bench_additional_values_01`
ON `bench_additional_values`(`bench_additional_type_id`,`bench_additional_value`);
CREATE INDEX IF NOT EXISTS `fk_bench_additional_values_01`
ON `bench_additional_values`(`bench_additional_type_id`);

CREATE TABLE `bench_additional_type_relations` (
  `bench_id` INT(10) NOT NULL,
  `bench_additional_type_id` SMALLINT(5) NOT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`bench_id`,`bench_additional_type_id`),
  CONSTRAINT `fk_bench_additional_type_relations_01`
    FOREIGN KEY (`bench_id`)
    REFERENCES `benchs` (`bench_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_bench_additional_type_relations_02`
    FOREIGN KEY (`bench_additional_type_id`)
    REFERENCES `bench_additional_types` (`bench_additional_type_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
);
CREATE INDEX IF NOT EXISTS `fk_bench_additional_type_relations_01`
ON `bench_additional_type_relations`(`bench_id`);
CREATE INDEX IF NOT EXISTS `fk_bench_additional_type_relations_02`
ON `bench_additional_type_relations`(`bench_additional_type_id`);

CREATE TABLE `bench_additional_relations` (
  `bench_value_id` INT(10) NOT NULL,
  `bench_additional_value_id` INT(10) NOT NULL,
  PRIMARY KEY (`bench_value_id`,`bench_additional_value_id`),
  CONSTRAINT `fk_bench_additional_relations_01`
    FOREIGN KEY (`bench_value_id`)
    REFERENCES `bench_values` (`bench_value_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_bench_additional_relations_02`
    FOREIGN KEY (`bench_additional_value_id`)
    REFERENCES `bench_additional_values` (`bench_additional_value_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
);
CREATE INDEX IF NOT EXISTS `fk_bench_additional_relations_01`
ON `bench_additional_relations`(`bench_value_id`);
CREATE INDEX IF NOT EXISTS `fk_bench_additional_relations_02`
ON `bench_additional_relations`(`bench_additional_value_id`);

CREATE TABLE `bench_backup_values` (
  `bench_backup_value_id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `bench_value_id` int(10) NOT NULL,
  `bench_id` int(10) NOT NULL,
  `bench_subsume_type_id` tinyint(3) NOT NULL,
  `bench_value` float DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT `fk_bench_backup_values_01`
    FOREIGN KEY (`bench_id`)
    REFERENCES `benchs` (`bench_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_bench_backup_values_02`
    FOREIGN KEY (`bench_subsume_type_id`)
    REFERENCES `bench_subsume_types` (`bench_subsume_type_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_bench_backup_values_03`
    FOREIGN KEY (`bench_value_id`)
    REFERENCES `bench_values` (`bench_value_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
);
CREATE INDEX IF NOT EXISTS `fk_bench_backup_values_01`
ON `bench_backup_values`(`bench_id`);
CREATE INDEX IF NOT EXISTS `fk_bench_backup_values_02`
ON `bench_backup_values`(`bench_subsume_type_id`);
CREATE INDEX IF NOT EXISTS `fk_bench_backup_values_03`
ON `bench_backup_values`(`bench_value_id`);

CREATE TABLE `bench_backup_additional_relations` (
  `bench_backup_value_id` int(10) NOT NULL,
  `bench_additional_value_id` int(10) NOT NULL,
  PRIMARY KEY (`bench_backup_value_id`,`bench_additional_value_id`),
  CONSTRAINT `fk_bench_backup_additional_relations_01`
    FOREIGN KEY (`bench_backup_value_id`)
    REFERENCES `bench_backup_values` (`bench_backup_value_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_bench_backup_additional_relations_02`
    FOREIGN KEY (`bench_additional_value_id`)
    REFERENCES `bench_additional_values` (`bench_additional_value_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
);
CREATE INDEX IF NOT EXISTS `fk_bench_backup_additional_relations_01`
ON `bench_backup_additional_relations`(`bench_backup_value_id`);
CREATE INDEX IF NOT EXISTS `fk_bench_backup_additional_relations_02`
ON `bench_backup_additional_relations`(`bench_additional_value_id`);

INSERT INTO bench_subsume_types
    ( bench_subsume_type, bench_subsume_type_rank, datetime_strftime_pattern, created_at )
VALUES
    ( 'atomic'  , 1, NULL           , DATE('now') )
;
INSERT INTO bench_subsume_types
    ( bench_subsume_type, bench_subsume_type_rank, datetime_strftime_pattern, created_at )
VALUES
    ( 'second'  , 2, '%Y%m%d%H%M%S' , DATE('now') )
;
INSERT INTO bench_subsume_types
    ( bench_subsume_type, bench_subsume_type_rank, datetime_strftime_pattern, created_at )
VALUES
    ( 'minute'  , 3, '%Y%m%d%H%M'   , DATE('now') )
;
INSERT INTO bench_subsume_types
    ( bench_subsume_type, bench_subsume_type_rank, datetime_strftime_pattern, created_at )
VALUES
    ( 'hour'    , 4, '%Y%m%d%H'     , DATE('now') )
;
INSERT INTO bench_subsume_types
    ( bench_subsume_type, bench_subsume_type_rank, datetime_strftime_pattern, created_at )
VALUES
    ( 'day'     , 5, '%Y%m%d'       , DATE('now') )
;
INSERT INTO bench_subsume_types
    ( bench_subsume_type, bench_subsume_type_rank, datetime_strftime_pattern, created_at )
VALUES
    ( 'week'    , 6, '%Y%W'         , DATE('now') )
;
INSERT INTO bench_subsume_types
    ( bench_subsume_type, bench_subsume_type_rank, datetime_strftime_pattern, created_at )
VALUES
    ( 'month'   , 7, '%Y%m'         , DATE('now') )
;
INSERT INTO bench_subsume_types
    ( bench_subsume_type, bench_subsume_type_rank, datetime_strftime_pattern, created_at )
VALUES
    ( 'year'    , 8, '%Y'           , DATE('now') )
;
