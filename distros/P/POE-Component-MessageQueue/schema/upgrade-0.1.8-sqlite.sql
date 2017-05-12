CREATE TABLE meta
(
	key   varchar(255) primary key,
	value varchar(255)
);
INSERT INTO meta (key, value) VALUES ('version', '0.1.8');

ALTER TABLE messages RENAME TO old_messages;

CREATE TABLE messages
(
	message_id  varchar(255) primary key,
	destination varchar(255) not null,
	persistent  char(1) default '1' not null,
	in_use_by   int,
	body        text,
	timestamp   int,
	size        int
);

CREATE INDEX id_index          ON messages ( message_id );
CREATE INDEX timestamp_index   ON messages ( timestamp );
CREATE INDEX destination_index ON messages ( destination );
CREATE INDEX in_use_by_index   ON messages ( in_use_by );

INSERT INTO messages 
      (message_id, destination, persistent, in_use_by, 
       body, timestamp, size)
SELECT message_id, destination, persistent, in_use_by,
       body, timestamp, size 
FROM old_messages;

