
ALTER TABLE messages MODIFY COLUMN in_use_by VARCHAR(255);

UPDATE meta SET value = '0.2.10' WHERE `key` = 'version';

