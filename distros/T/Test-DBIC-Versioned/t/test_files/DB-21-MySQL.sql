CREATE TABLE `artist` (
  `id` integer unsigned NOT NULL auto_increment,
  `name` varchar(255) NOT NULL,
  PRIMARY KEY (`id`),
);

CREATE TABLE `song` (
  `id` integer unsigned NOT NULL auto_increment,
  `artist` varchar(255) NOT NULL,
  `artist_id` varchar(255) NOT NULL,
  `title` varchar(255) NOT NULL,
  PRIMARY KEY (`id`),
  INDEX `idx_artist_id` (`artist_id`),
  CONSTRAINT `idx_artist_id` FOREIGN KEY (`artist_id`) REFERENCES `artist` (`id`) ON UPDATE CASCADE
);
