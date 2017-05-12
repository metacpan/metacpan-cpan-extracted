
CREATE TABLE meta
(
	key   varchar(255) primary key,
	value varchar(255)
);
INSERT INTO meta (key, value) VALUES ('version', '0.2.10');

CREATE TABLE messages
(
	message_id  varchar(255) primary key,
	destination varchar(255) not null,
	persistent  char(1) default '1' not null,
	in_use_by   varchar(255),
	body        text,
	timestamp   decimal(15,5),
	size        int,
	deliver_at  int
);

-- Improves performance some bit:
CREATE INDEX id_index          ON messages ( message_id );
CREATE INDEX timestamp_index   ON messages ( timestamp );
CREATE INDEX destination_index ON messages ( destination );
CREATE INDEX in_use_by_index   ON messages ( in_use_by );
CREATE INDEX deliver_at        ON messages ( deliver_at );

