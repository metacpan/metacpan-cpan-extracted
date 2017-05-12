use `testrundb`;

-- bugfix float datatype problem
ALTER TABLE `testrundb`.`bench_values`
    CHANGE COLUMN `bench_value` `bench_value` VARCHAR(512) NULL DEFAULT NULL COMMENT 'value for bench data point'
;
ALTER TABLE `testrundb`.`bench_backup_values`
    CHANGE COLUMN `bench_value` `bench_value` VARCHAR(512) NULL DEFAULT NULL COMMENT 'value for bench data point'
;