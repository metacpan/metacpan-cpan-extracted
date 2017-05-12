SET FOREIGN_KEY_CHECKS=0;

DROP TABLE IF EXISTS `bench_units`;
CREATE TABLE `bench_units` (
  `bench_unit_id` tinyint(3) unsigned NOT NULL AUTO_INCREMENT COMMENT 'unique key (PK)',
  `bench_unit` varchar(128) NOT NULL COMMENT 'unique string identifier',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'creation date',
  PRIMARY KEY (`bench_unit_id`),
  UNIQUE KEY `ux_bench_units_01` (`bench_unit`)
) ENGINE=InnoDB COMMENT='units for benchmark data points';

DROP TABLE IF EXISTS `bench_backup_values`;
CREATE TABLE `bench_backup_values` (
  `bench_backup_value_id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'unique key (PK)',
  `bench_value_id` int(10) unsigned NOT NULL COMMENT 'FK to bench_values',
  `bench_id` int(10) unsigned NOT NULL COMMENT 'FK to benchs',
  `bench_subsume_type_id` tinyint(3) unsigned NOT NULL COMMENT 'FK to bench_subsume_types',
  `bench_value` float DEFAULT NULL COMMENT 'value for bench data point',
  `active` tinyint(3) unsigned NOT NULL COMMENT 'is entry still active (0=no,1=yes)',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'creation date',
  PRIMARY KEY (`bench_backup_value_id`),
  KEY `fk_bench_backup_values_01` (`bench_id`),
  KEY `fk_bench_backup_values_02` (`bench_subsume_type_id`),
  KEY `fk_bench_backup_values_03` (`bench_value_id`),
  CONSTRAINT `fk_bench_backup_values_01` FOREIGN KEY (`bench_id`) REFERENCES `benchs` (`bench_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_bench_backup_values_02` FOREIGN KEY (`bench_subsume_type_id`) REFERENCES `bench_subsume_types` (`bench_subsume_type_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_bench_backup_values_03` FOREIGN KEY (`bench_value_id`) REFERENCES `bench_values` (`bench_value_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB COMMENT='backup table for data points for benchmark';

DROP TABLE IF EXISTS `bench_additional_type_relations`;
CREATE TABLE `bench_additional_type_relations` (
  `bench_id` int(10) unsigned NOT NULL COMMENT 'FK to benchs (PK)',
  `bench_additional_type_id` smallint(5) unsigned NOT NULL COMMENT 'FK to bench_additional_types (PK)',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'creation date',
  PRIMARY KEY (`bench_id`,`bench_additional_type_id`),
  KEY `fk_bench_additional_values_01` (`bench_id`),
  KEY `fk_bench_additional_values_02` (`bench_additional_type_id`),
  CONSTRAINT `fk_bench_additional_type_relations_01` FOREIGN KEY (`bench_id`) REFERENCES `benchs` (`bench_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_bench_additional_type_relations_02` FOREIGN KEY (`bench_additional_type_id`) REFERENCES `bench_additional_types` (`bench_additional_type_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB COMMENT='additional values for benchmark data point';

DROP TABLE IF EXISTS `bench_additional_types`;
CREATE TABLE `bench_additional_types` (
  `bench_additional_type_id` smallint(5) unsigned NOT NULL AUTO_INCREMENT COMMENT 'unique key (PK)',
  `bench_additional_type` varchar(512) NOT NULL COMMENT 'unique string identifier',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'creation date',
  PRIMARY KEY (`bench_additional_type_id`),
  UNIQUE KEY `ux_bench_additional_types_01` (`bench_additional_type`)
) ENGINE=InnoDB COMMENT='types of additional values for benchmark data points';

DROP TABLE IF EXISTS `benchs`;
CREATE TABLE `benchs` (
  `bench_id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'unique key (PK)',
  `bench_unit_id` tinyint(3) unsigned DEFAULT NULL,
  `bench` varchar(512) NOT NULL COMMENT 'unique string identifier',
  `active` tinyint(3) unsigned NOT NULL COMMENT 'is entry still active (1=yes,0=no)',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'creation date',
  PRIMARY KEY (`bench_id`),
  UNIQUE KEY `ux_benchs_01` (`bench`),
  KEY `fk_benchs_01` (`bench_unit_id`),
  CONSTRAINT `fk_benchs_01` FOREIGN KEY (`bench_unit_id`) REFERENCES `bench_units` (`bench_unit_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB COMMENT='containg benchmark head data';

DROP TABLE IF EXISTS `bench_additional_relations`;
CREATE TABLE `bench_additional_relations` (
  `bench_value_id` int(10) unsigned NOT NULL COMMENT 'FK to bench_values',
  `bench_additional_value_id` int(10) unsigned NOT NULL COMMENT 'FK to bench_additional_values',
  `active` tinyint(3) unsigned NOT NULL COMMENT 'is entry still active (0=no,1=yes)',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'creation date',
  PRIMARY KEY (`bench_value_id`,`bench_additional_value_id`),
  KEY `fk_bench_additional_relations_01` (`bench_value_id`),
  KEY `fk_bench_additional_relations_02` (`bench_additional_value_id`),
  CONSTRAINT `fk_bench_additional_relations_01` FOREIGN KEY (`bench_value_id`) REFERENCES `bench_values` (`bench_value_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_bench_additional_relations_02` FOREIGN KEY (`bench_additional_value_id`) REFERENCES `bench_additional_values` (`bench_additional_value_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB COMMENT='add additional values to benchmarks';

DROP TABLE IF EXISTS `bench_additional_values`;
CREATE TABLE `bench_additional_values` (
  `bench_additional_value_id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'unique key (PK)',
  `bench_additional_type_id` smallint(5) unsigned NOT NULL COMMENT 'FK to bench_additional_types',
  `bench_additional_value` varchar(512) NOT NULL COMMENT 'additional value',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'creation date',
  PRIMARY KEY (`bench_additional_value_id`),
  UNIQUE KEY `ux_bench_additional_values_01` (`bench_additional_type_id`,`bench_additional_value`),
  KEY `fk_bench_additional_values_01` (`bench_additional_type_id`),
  CONSTRAINT `fk_bench_additional_values_01` FOREIGN KEY (`bench_additional_type_id`) REFERENCES `bench_additional_types` (`bench_additional_type_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB COMMENT='additional values for benchmark data point';

DROP TABLE IF EXISTS `bench_backup_additional_relations`;
CREATE TABLE `bench_backup_additional_relations` (
  `bench_backup_value_id` int(10) unsigned NOT NULL COMMENT 'FK to bench_backup_values',
  `bench_additional_value_id` int(10) unsigned NOT NULL COMMENT 'FK to bench_additional_values',
  `active` tinyint(3) unsigned NOT NULL COMMENT 'is entry still active (0=no,1=yes)',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'creation date',
  PRIMARY KEY (`bench_backup_value_id`,`bench_additional_value_id`),
  KEY `fk_bench_backup_additional_relations_01` (`bench_backup_value_id`),
  KEY `fk_bench_backup_additional_relations_02` (`bench_additional_value_id`),
  CONSTRAINT `fk_bench_backup_additional_relations_01` FOREIGN KEY (`bench_backup_value_id`) REFERENCES `bench_backup_values` (`bench_backup_value_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_bench_backup_additional_relations_02` FOREIGN KEY (`bench_additional_value_id`) REFERENCES `bench_additional_values` (`bench_additional_value_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB COMMENT='add additional values to benchmarks';

DROP TABLE IF EXISTS `bench_subsume_types`;
CREATE TABLE `bench_subsume_types` (
  `bench_subsume_type_id` tinyint(3) unsigned NOT NULL AUTO_INCREMENT COMMENT 'unique key (PK)',
  `bench_subsume_type` varchar(32) NOT NULL COMMENT 'unique string identifier',
  `bench_subsume_type_rank` tinyint(3) unsigned NOT NULL COMMENT 'subsume type order',
  `datetime_strftime_pattern` varchar(32) DEFAULT NULL COMMENT 'format pattern for per DateTime->strftime for grouping',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'creation date',
  PRIMARY KEY (`bench_subsume_type_id`),
  UNIQUE KEY `ux_bench_subsume_types_01` (`bench_subsume_type`)
) ENGINE=InnoDB COMMENT='types of subsume values';

INSERT INTO `bench_subsume_types` VALUES
    (1,'atomic',1,NULL,'2013-09-30 11:18:24'),
    (2,'second',2,'%Y%m%d%H%M%S','2013-09-30 11:18:24'),
    (3,'minute',3,'%Y%m%d%H%M','2013-09-30 11:18:24'),
    (4,'hour',4,'%Y%m%d%H','2013-09-30 11:18:24'),
    (5,'day',5,'%Y%m%d','2013-09-30 11:18:24'),
    (6,'week',6,'%Y%W','2013-09-30 11:18:24'),
    (7,'month',7,'%Y%m','2013-09-30 11:18:24'),
    (8,'year',8,'%Y','2013-09-30 11:18:24')
;

DROP TABLE IF EXISTS `bench_values`;
CREATE TABLE `bench_values` (
  `bench_value_id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'unique key (PK)',
  `bench_id` int(10) unsigned NOT NULL COMMENT 'FK to benchs',
  `bench_subsume_type_id` tinyint(3) unsigned NOT NULL COMMENT 'FK to bench_subsume_types',
  `bench_value` float DEFAULT NULL COMMENT 'value for bench data point',
  `active` tinyint(3) unsigned NOT NULL COMMENT 'is entry still active (0=no,1=yes)',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'creation date',
  PRIMARY KEY (`bench_value_id`),
  KEY `fk_bench_values_01` (`bench_id`),
  KEY `fk_bench_values_02` (`bench_subsume_type_id`),
  CONSTRAINT `fk_bench_values_01` FOREIGN KEY (`bench_id`) REFERENCES `benchs` (`bench_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_bench_values_02` FOREIGN KEY (`bench_subsume_type_id`) REFERENCES `bench_subsume_types` (`bench_subsume_type_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB COMMENT='containing data points for benchmark';

SET FOREIGN_KEY_CHECKS=1;