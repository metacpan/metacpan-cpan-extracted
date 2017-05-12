
ALTER TABLE messages MODIFY COLUMN timestamp decimal(15,5);
ALTER TABLE messages MODIFY COLUMN persistent enum('1', '0') default '1';

UPDATE meta SET value = '0.2.9' WHERE `key` = 'version';

