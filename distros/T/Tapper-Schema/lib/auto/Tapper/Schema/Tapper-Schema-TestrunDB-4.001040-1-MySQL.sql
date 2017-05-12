use `testrundb`;

ALTER TABLE `testrundb`.`chart_line_axis_columns`
    CHANGE COLUMN `chart_line_axis_column` `chart_line_axis_column` VARCHAR(512) CHARACTER SET 'utf8' COLLATE 'utf8_general_ci' NOT NULL
;

DROP TABLE IF EXISTS `testrundb`.`chart_line_restrictions`;
CREATE  TABLE `testrundb`.`chart_line_restrictions` (
  `chart_line_restriction_id` INT UNSIGNED NOT NULL AUTO_INCREMENT ,
  `chart_line_id` INT UNSIGNED NOT NULL ,
  `chart_line_restriction_operator` VARCHAR(4) NOT NULL COMMENT 'operator for restriction' ,
  `chart_line_restriction_column` VARCHAR(512) NOT NULL COMMENT 'a name of a bench_additional_type' ,
  `is_template_restriction` TINYINT UNSIGNED NOT NULL ,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'creation date' ,
  PRIMARY KEY (`chart_line_restriction_id`),
  INDEX `fk_chart_line_restrictions_01` (`chart_line_id` ASC),
  CONSTRAINT `fk_chart_line_restrictions_01`
    FOREIGN KEY (`chart_line_id` )
    REFERENCES `testrundb`.`chart_lines` (`chart_line_id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
)
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_general_ci
COMMENT = 'contains \"where\" clause for a specific Tapper::Benchmark line'
;

CREATE  TABLE `testrundb`.`chart_line_restriction_values` (
  `chart_line_restriction_value_id` INT UNSIGNED NOT NULL AUTO_INCREMENT ,
  `chart_line_restriction_id` INT UNSIGNED NOT NULL ,
  `chart_line_restriction_value` VARCHAR(512) NOT NULL ,
  PRIMARY KEY (`chart_line_restriction_value_id`) ,
  INDEX `fk_chart_line_restriction_values_01` (`chart_line_restriction_id` ASC) ,
  CONSTRAINT `fk_chart_line_restriction_values_01`
    FOREIGN KEY (`chart_line_restriction_id` )
    REFERENCES `testrundb`.`chart_line_restrictions` (`chart_line_restriction_id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
)
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_general_ci
COMMENT = 'contains \"where\" clause values for a specific Tapper::Benchmark line'
;