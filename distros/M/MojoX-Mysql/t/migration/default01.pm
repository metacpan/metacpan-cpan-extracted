package migration::default01;

1;

__DATA__

@@ 1
CREATE TABLE IF NOT EXISTS `test1` (
	`test_id` int unsigned NOT NULL AUTO_INCREMENT,
	`text` varchar(200) NOT NULL,
	PRIMARY KEY (`test_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

@@ 2
CREATE TABLE IF NOT EXISTS `test2` (
	`test_id` int unsigned NOT NULL AUTO_INCREMENT,
	`text` varchar(200) NOT NULL,
	PRIMARY KEY (`test_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;


