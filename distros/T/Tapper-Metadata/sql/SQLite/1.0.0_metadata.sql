DROP TABLE IF EXISTS `testrun_metadata_lines`;
DROP TABLE IF EXISTS `testrun_metadata_headers`;

CREATE TABLE `testrun_metadata_headers` (
  `testrun_metadata_header_id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `testrun_id` int(11) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT `fk_testrun_metadata_header_01` FOREIGN KEY (`testrun_id`) REFERENCES `testrun` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
);

CREATE INDEX IF NOT EXISTS `fk_testrun_metadata_header_01` ON `testrun_metadata_headers`(`testrun_id`);

CREATE TABLE `testrun_metadata_lines` (
  `testrun_metadata_header_id` int(10) NOT NULL,
  `bench_additional_value_id` int(10) NOT NULL,
  PRIMARY KEY (`testrun_metadata_header_id`,`bench_additional_value_id`),
  CONSTRAINT `fk_testrun_metadata_lines_01` FOREIGN KEY (`testrun_metadata_header_id`) REFERENCES `testrun_metadata_headers` (`testrun_metadata_header_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_testrun_metadata_lines_02` FOREIGN KEY (`bench_additional_value_id`) REFERENCES `bench_additional_values` (`bench_additional_value_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
);

CREATE INDEX IF NOT EXISTS `fk_testrun_metadata_lines_01` ON `testrun_metadata_lines`(`testrun_metadata_header_id`);
CREATE INDEX IF NOT EXISTS `fk_testrun_metadata_lines_02` ON `testrun_metadata_lines`(`bench_additional_value_id`);
