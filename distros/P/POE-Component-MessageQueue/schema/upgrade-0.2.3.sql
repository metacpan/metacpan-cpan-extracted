
ALTER TABLE messages ADD COLUMN deliver_at INT;
CREATE INDEX deliver_at_index ON messages ( deliver_at );

UPDATE meta SET value = '0.2.3' where key = 'version';

