use `testrundb`;

ALTER TABLE `testrundb`.`charts`
    ADD COLUMN `order_by_x_axis` TINYINT UNSIGNED NOT NULL DEFAULT '0'  AFTER `chart_name` ,
    ADD COLUMN `order_by_y_axis` TINYINT UNSIGNED NOT NULL DEFAULT '0'  AFTER `order_by_x_axis`,
    ADD COLUMN `active` TINYINT(3) UNSIGNED NOT NULL DEFAULT '0'  AFTER `order_by_y_axis`,
    ADD COLUMN `updated_at` TIMESTAMP NULL  AFTER `created_at`
;

UPDATE `testrundb`.`charts`
SET order_by_x_axis = 1, active = 1
WHERE chart_id BETWEEN 1 AND 1000;

DROP TABLE IF EXISTS `chart_tiny_urls`;
CREATE TABLE `chart_tiny_urls` (
  `chart_tiny_url_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `visit_count` int(10) unsigned NOT NULL,
  `last_visited` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`chart_tiny_url_id`)
);

DROP TABLE IF EXISTS `chart_tiny_url_lines`;
CREATE TABLE `chart_tiny_url_lines` (
  `chart_tiny_url_line_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `chart_tiny_url_id` int(10) unsigned NOT NULL,
  `chart_line_id` int(10) unsigned NOT NULL,
  PRIMARY KEY (`chart_tiny_url_line_id`)
);

DROP TABLE IF EXISTS `chart_tiny_url_relations`;
CREATE TABLE `chart_tiny_url_relations` (
  `chart_tiny_url_line_id` int(10) unsigned NOT NULL,
  `bench_value_id` int(10) unsigned NOT NULL,
  PRIMARY KEY (`chart_tiny_url_line_id`,`bench_value_id`),
  KEY `fk_chart_tiny_url_relations_01` (`chart_tiny_url_line_id`),
  KEY `fk_chart_tiny_url_relations_02` (`bench_value_id`),
  CONSTRAINT `fk_chart_tiny_url_relations_01`
    FOREIGN KEY (`chart_tiny_url_line_id`)
    REFERENCES `chart_tiny_url_lines` (`chart_tiny_url_line_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_chart_tiny_url_relations_02`
    FOREIGN KEY (`bench_value_id`)
    REFERENCES `bench_values` (`bench_value_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
);