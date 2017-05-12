
-- Upgrade script from version 20 to 21
ALTER TABLE `song`
    ADD COLUMN `artist_id` varchar(255) NOT NULL,
    ADD INDEX `idx_artist_id` (`artist_id`),
    ADD CONSTRAINT `idx_artist_id` FOREIGN KEY (`artist_id`) REFERENCES `artist` (`id`) ON UPDATE CASCADE;
