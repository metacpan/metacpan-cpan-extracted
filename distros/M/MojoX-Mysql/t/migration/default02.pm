package migration::default02;

1;

__DATA__

@@ 3
CREATE TABLE IF NOT EXISTS `test3` (
	`test_id` int unsigned NOT NULL AUTO_INCREMENT,
	`text` varchar(200) NOT NULL,
	PRIMARY KEY (`test_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

@@ 4
CREATE TABLE IF NOT EXISTS `test4` (
	`test_id` int unsigned NOT NULL AUTO_INCREMENT,
	`text` varchar(200) NOT NULL,
	PRIMARY KEY (`test_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;


