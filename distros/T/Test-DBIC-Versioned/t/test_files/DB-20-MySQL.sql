CREATE TABLE `artist` (
  `id` integer unsigned NOT NULL auto_increment,
  `name` varchar(255) NOT NULL,
  PRIMARY KEY (`id`),
);

CREATE TABLE `song` (
  `id` integer unsigned NOT NULL auto_increment,
  `artist` varchar(255) NOT NULL,
  `title` varchar(255) NOT NULL,
  PRIMARY KEY (`id`),
);
