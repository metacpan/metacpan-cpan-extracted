use `testrundb`;

SET FOREIGN_KEY_CHECKS = 0;

-- add new column for support of numeric checks
ALTER TABLE `testrundb`.`chart_line_restrictions`
    ADD COLUMN `is_numeric_restriction` TINYINT(3) UNSIGNED NOT NULL COMMENT 'restriction is numerically checked'  AFTER `is_template_restriction` ,
    CHANGE COLUMN `is_template_restriction` `is_template_restriction` TINYINT(3) UNSIGNED NOT NULL COMMENT 'values for restriction check will be added by caller'
;

UPDATE
    chart_line_restrictions clr
SET
    clr.is_numeric_restriction = (
        SELECT
            MIN(clrv.chart_line_restriction_value REGEXP '^(-|\\+){0,1}([0-9]+\\.[0-9]*|[0-9]*\\.[0-9]+|[0-9]+)$')
        FROM
            chart_line_restriction_values clrv
        WHERE
            clr.chart_line_restriction_id = clrv.chart_line_restriction_id
    )
;

-- add version management for charts
ALTER TABLE `testrundb`.`chart_lines`
    DROP FOREIGN KEY `fk_chart_lines_01`
;
ALTER TABLE `testrundb`.`charts`
    ADD COLUMN `chart_id` INT(10) UNSIGNED NOT NULL  AFTER `chart_version_id` ,
    CHANGE COLUMN `chart_id` `chart_version_id` INT(10) UNSIGNED NOT NULL AUTO_INCREMENT  ,
    RENAME TO  `testrundb`.`chart_versions`
;
UPDATE `testrundb`.`chart_versions`
SET `chart_id` = `chart_version_id`
;
ALTER TABLE `testrundb`.`chart_lines`
    CHANGE COLUMN `chart_id` `chart_version_id` INT(10) UNSIGNED NOT NULL
;

ALTER TABLE `testrundb`.`chart_lines`
  ADD CONSTRAINT `fk_chart_lines_01`
  FOREIGN KEY (`chart_version_id` )
  REFERENCES `testrundb`.`chart_versions` (`chart_version_id` )
  ON DELETE NO ACTION
  ON UPDATE NO ACTION
;
DROP TABLE IF EXISTS `testrundb`.`charts`;
CREATE  TABLE `testrundb`.`charts` (
  `chart_id` INT UNSIGNED NOT NULL AUTO_INCREMENT ,
  `active` TINYINT(3) UNSIGNED NOT NULL ,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ,
  `updated_at` TIMESTAMP NULL ,
  PRIMARY KEY (`chart_id`) ,
  INDEX `ix_charts_01` (`active` ASC) )
;
ALTER TABLE `testrundb`.`chart_versions`
      DROP FOREIGN KEY `fk_charts_01`
    , DROP FOREIGN KEY `fk_charts_02`
    , DROP FOREIGN KEY `fk_charts_03`
    , DROP FOREIGN KEY `fk_charts_04`
    , DROP INDEX `fk_charts_01`
    , DROP INDEX `fk_charts_02`
    , DROP INDEX `fk_charts_03`
    , DROP INDEX `fk_charts_04`
    , ADD INDEX `fk_chart_versions_01` (`chart_type_id` ASC)
    , ADD INDEX `fk_chart_versions_02` (`owner_id` ASC)
    , ADD INDEX `fk_chart_versions_03` (`chart_axis_type_x_id` ASC)
    , ADD INDEX `fk_chart_versions_04` (`chart_axis_type_y_id` ASC)
;
ALTER TABLE `testrundb`.`chart_versions`
    ADD CONSTRAINT `fk_chart_versions_01`
        FOREIGN KEY (`chart_type_id` )
        REFERENCES `testrundb`.`chart_types` (`chart_type_id` )
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
    ADD CONSTRAINT `fk_chart_versions_02`
        FOREIGN KEY (`owner_id` )
        REFERENCES `testrundb`.`owner` (`id` )
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
    ADD CONSTRAINT `fk_chart_versions_03`
        FOREIGN KEY (`chart_axis_type_x_id` )
        REFERENCES `testrundb`.`chart_axis_types` (`chart_axis_type_id` )
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
    ADD CONSTRAINT `fk_chart_versions_04`
        FOREIGN KEY (`chart_axis_type_y_id` )
        REFERENCES `testrundb`.`chart_axis_types` (`chart_axis_type_id` )
        ON DELETE NO ACTION
        ON UPDATE NO ACTION
;
INSERT INTO `testrundb`.`charts` (
    `chart_id`, `active`, `created_at`, `updated_at`
)
SELECT chart_id, active, created_at, updated_at
FROM `testrundb`.`chart_versions`
;
ALTER TABLE `testrundb`.`chart_versions`
    DROP COLUMN `active`,
    ADD COLUMN `chart_version` TINYINT(3) UNSIGNED NOT NULL DEFAULT 1  AFTER `chart_axis_type_y_id` ,
    ADD CONSTRAINT `fk_chart_versions_05`
        FOREIGN KEY (`chart_id` )
        REFERENCES `testrundb`.`charts` (`chart_id` )
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
    ADD INDEX `fk_chart_versions_05` (`chart_id` ASC),
    ADD UNIQUE INDEX `ux_chart_versions_01` (`chart_id` ASC, `chart_version` ASC)
;

ALTER TABLE `testrundb`.`bench_values`
    ADD INDEX `ix_bench_values_01` (`bench_value` ASC)
;

DROP TABLE IF EXISTS `testrundb`.`chart_tags`;
CREATE  TABLE `testrundb`.`chart_tags` (
  `chart_tag_id` SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT ,
  `chart_tag` VARCHAR(64) NOT NULL ,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ,
  PRIMARY KEY (`chart_tag_id`) ,
  UNIQUE INDEX `ux_chart_tags_01` (`chart_tag` ASC)
);

DROP TABLE IF EXISTS `testrundb`.`chart_tag_relations`;
CREATE  TABLE `testrundb`.`chart_tag_relations` (
  `chart_id` INT UNSIGNED NOT NULL ,
  `chart_tag_id` SMALLINT UNSIGNED NOT NULL ,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ,
  PRIMARY KEY (`chart_id`, `chart_tag_id`) ,
  INDEX `fk_chart_tag_relations_01` (`chart_id` ASC) ,
  INDEX `fk_chart_tag_relations_02` (`chart_tag_id` ASC) ,
  CONSTRAINT `fk_chart_tag_relations_01`
    FOREIGN KEY (`chart_id` )
    REFERENCES `testrundb`.`charts` (`chart_id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_chart_tag_relations_02`
    FOREIGN KEY (`chart_tag_id` )
    REFERENCES `testrundb`.`chart_tags` (`chart_tag_id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
);

ALTER TABLE `testrundb`.`chart_line_additionals`
    CHANGE COLUMN `chart_line_additional_column` `chart_line_additional_column` VARCHAR(512) NOT NULL
;

ALTER TABLE `testrundb`.`chart_line_additionals`
    CHANGE COLUMN `chart_line_additional_column` `chart_line_additional_column` VARCHAR(512) NOT NULL,
    CHANGE COLUMN `chart_line_additional_url` `chart_line_additional_url` VARCHAR(1024) NULL DEFAULT NULL
;

ALTER TABLE `testrundb`.`chart_line_axis_elements`
    ADD UNIQUE INDEX `ux_chart_line_axis_elements_01` (`chart_line_id` ASC, `chart_line_axis` ASC, `chart_line_axis_element_number` ASC)
;

ALTER TABLE `testrundb`.`chart_lines`
    CHANGE COLUMN `chart_line_name` `chart_line_name` VARCHAR(128) NOT NULL,
    ADD UNIQUE INDEX `ux_chart_lines_01` (`chart_version_id` ASC, `chart_line_name` ASC)
;

ALTER TABLE `testrundb`.`chart_types`
    ADD UNIQUE INDEX `ux_chart_types_01` (`chart_type_name` ASC),
    ADD UNIQUE INDEX `ux_chart_types_02` (`chart_type_flot_name` ASC)
;

INSERT INTO chart_tags
    ( chart_tag, created_at )
SELECT
    DISTINCT IFNULL( o.login, o.name ), NOW()
FROM
    chart_versions cv
    JOIN owner o
        ON ( cv.owner_id = o.id )
;

INSERT INTO chart_tag_relations
    ( chart_id, chart_tag_id, created_at )
SELECT
    cv.chart_id,
    ct.chart_tag_id,
    NOW()
FROM
    chart_versions cv
    JOIN charts c
        ON ( cv.chart_id = c.chart_id )
    JOIN owner o
        ON ( cv.owner_id = o.id )
    JOIN chart_tags ct
        ON ( IFNULL( o.login, o.name ) = ct.chart_tag )
WHERE
    cv.chart_version >= ALL(
        SELECT cvi.chart_version
        FROM chart_versions cvi
        WHERE cvi.chart_id = cv.chart_id
    )
;

ALTER TABLE `testrundb`.`chart_versions`
    DROP FOREIGN KEY `fk_chart_versions_02`
;
ALTER TABLE `testrundb`.`chart_versions`
    DROP COLUMN `owner_id`,
    DROP INDEX `fk_chart_versions_02`
;


SET FOREIGN_KEY_CHECKS = 1;