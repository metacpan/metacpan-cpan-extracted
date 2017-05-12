use testrundb;

DROP TABLE IF EXISTS `chart_line_axis_elements`;
CREATE TABLE `chart_line_axis_elements` (
  `chart_line_axis_element_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `chart_line_id` int(10) unsigned NOT NULL,
  `chart_line_axis` char(1) NOT NULL,
  `chart_line_axis_element_number` tinyint(3) unsigned NOT NULL,
  PRIMARY KEY (`chart_line_axis_element_id`),
  KEY `fk_chart_line_axis_elements_01` (`chart_line_id`),
  CONSTRAINT `fk_chart_line_axis_elements_01`
    FOREIGN KEY (`chart_line_id`)
    REFERENCES `chart_lines` (`chart_line_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `chart_line_axis_columns`;
CREATE TABLE `chart_line_axis_columns` (
  `chart_line_axis_element_id` int(10) unsigned NOT NULL,
  `chart_line_axis_column` varchar(128) NOT NULL,
  PRIMARY KEY (`chart_line_axis_element_id`),
  KEY `fk_chart_line_axis_columns_01` (`chart_line_axis_element_id`),
  CONSTRAINT `fk_chart_line_axis_columns_01`
    FOREIGN KEY (`chart_line_axis_element_id`)
    REFERENCES `chart_line_axis_elements` (`chart_line_axis_element_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `chart_line_axis_separators`;
CREATE TABLE `chart_line_axis_separators` (
  `chart_line_axis_element_id` int(10) unsigned NOT NULL,
  `chart_line_axis_separator` varchar(128) NOT NULL,
  PRIMARY KEY (`chart_line_axis_element_id`),
  KEY `fk_chart_line_axis_separators_01` (`chart_line_axis_element_id`),
  CONSTRAINT `fk_chart_line_axis_separators_01`
    FOREIGN KEY (`chart_line_axis_element_id`)
    REFERENCES `chart_line_axis_elements` (`chart_line_axis_element_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

INSERT INTO `chart_line_axis_elements`
    ( chart_line_id, chart_line_axis, chart_line_axis_element_number )
    SELECT chart_line_id, 'x', 1 FROM chart_lines
UNION
    SELECT chart_line_id, 'y', 1 FROM chart_lines
;

INSERT INTO `chart_line_axis_columns`
    ( chart_line_axis_element_id, chart_line_axis_column )
    SELECT
        chart_line_axis_element_id,
        chart_axis_x_column
    FROM
        chart_line_axis_elements clae
        JOIN chart_lines cl
            ON ( clae.chart_line_id = cl.chart_line_id )
    WHERE
        chart_line_axis = 'x'
        AND chart_line_axis_element_number = 1
UNION
    SELECT
        chart_line_axis_element_id,
        chart_axis_x_column
    FROM
        chart_line_axis_elements clae
        JOIN chart_lines cl
            ON ( clae.chart_line_id = cl.chart_line_id )
    WHERE
        chart_line_axis = 'y'
        AND chart_line_axis_element_number = 1
;

ALTER TABLE `chart_line_additionals`
    CHANGE COLUMN `chart_line_additional_column` `chart_line_additional_column` VARCHAR(128) NOT NULL
;

ALTER TABLE `chart_lines`
    DROP COLUMN `chart_axis_x_column`,
    DROP COLUMN `chart_axis_y_column`
;