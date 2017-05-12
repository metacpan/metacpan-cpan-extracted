SET foreign_key_checks=0;

--
-- Table: `author`
--
CREATE TABLE `author` (
  `id` INTEGER NOT NULL auto_increment,
  `name` VARCHAR(255) NULL,
  UNIQUE `name_uniq` (`name`),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARACTER SET utf8;

--
-- Table: `module`
--
CREATE TABLE `module` (
  `id` INTEGER NOT NULL auto_increment,
  `name` VARCHAR(255) NULL,
  `author_id` INTEGER NULL,
  INDEX `author_id_idx` (`author_id`),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARACTER SET utf8;

SET foreign_key_checks=1;


