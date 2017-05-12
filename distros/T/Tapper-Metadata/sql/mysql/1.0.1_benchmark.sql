use `testrundb`;

DROP TABLE IF EXISTS `testrundb`.`bench_suites`;
CREATE  TABLE `testrundb`.`bench_suites` (
  `bench_suite_id` INT(10) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'unique key (PK)' ,
  `bench_suite` VARCHAR(255) NOT NULL COMMENT 'unique string identifier' ,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'creation date' ,
  PRIMARY KEY (`bench_suite_id`) ,
  UNIQUE INDEX `ux_bench_suites_01` (`bench_suite` ASC) )
COMMENT = 'containing test suites for benchmarks';

ALTER TABLE `testrundb`.`benchs`
    DROP FOREIGN KEY `fk_benchs_01`
;
ALTER TABLE `testrundb`.`benchs`
    ADD COLUMN `bench_suite_id` INT(10) UNSIGNED NULL COMMENT 'FK to testrundb.bench_suites.bench_suite_id'  AFTER `bench_unit_id` ,
    CHANGE COLUMN `bench_unit_id` `bench_unit_id` TINYINT(3) UNSIGNED NULL DEFAULT NULL COMMENT 'FK to testrundb.bench_units.bench_unit_id'  , 
    ADD CONSTRAINT `fk_benchs_01`
        FOREIGN KEY (`bench_unit_id` )
        REFERENCES `testrundb`.`bench_units` (`bench_unit_id` )
        ON DELETE NO ACTION
        ON UPDATE NO ACTION, 
    ADD CONSTRAINT `fk_benchs_02`
        FOREIGN KEY (`bench_suite_id` )
        REFERENCES `testrundb`.`bench_suites` (`bench_suite_id` )
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
    ADD INDEX `fk_benchs_02` (`bench_suite_id` ASC)
;