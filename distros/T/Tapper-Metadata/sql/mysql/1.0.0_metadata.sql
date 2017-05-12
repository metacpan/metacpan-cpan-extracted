SET FOREIGN_KEY_CHECKS=0;

DROP TABLE IF EXISTS `testrun_metadata_lines`;
DROP TABLE IF EXISTS `testrun_metadata_headers`;

CREATE TABLE `testrun_metadata_headers` (
  `testrun_metadata_header_id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'unique key (PK)',
  `testrun_id` int(11) NOT NULL COMMENT 'FK to testrundb.testrun',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'creation date',
  PRIMARY KEY (`testrun_metadata_header_id`),
  KEY `fk_testrun_metadata_header_01` (`testrun_id`),
  CONSTRAINT `fk_testrun_metadata_header_01` FOREIGN KEY (`testrun_id`) REFERENCES `testrun` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8 ROW_FORMAT=DYNAMIC COMMENT='containing data points for benchmark';

CREATE TABLE `testrun_metadata_lines` (
  `testrun_metadata_header_id` int(10) unsigned NOT NULL COMMENT 'FK to testrundb.testrun',
  `bench_additional_value_id` int(10) unsigned NOT NULL COMMENT 'FK to testrundb.bench_additional_values',
  PRIMARY KEY (`testrun_metadata_header_id`,`bench_additional_value_id`),
  KEY `fk_testrun_metadata_lines_01` (`testrun_metadata_header_id`),
  KEY `fk_testrun_metadata_lines_02` (`bench_additional_value_id`),
  CONSTRAINT `fk_testrun_metadata_lines_01` FOREIGN KEY (`testrun_metadata_header_id`) REFERENCES `testrun_metadata_headers` (`testrun_metadata_header_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_testrun_metadata_lines_02` FOREIGN KEY (`bench_additional_value_id`) REFERENCES `bench_additional_values` (`bench_additional_value_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8 ROW_FORMAT=DYNAMIC COMMENT='containing relations for additional values metadata header';

SET FOREIGN_KEY_CHECKS=1;