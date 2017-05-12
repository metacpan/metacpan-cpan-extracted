CREATE TABLE test (
login varchar(64) NOT NULL,
password varchar(128) NOT NULL,
uid integer unsigned NOT NULL,
gecos varchar(64) NOT NULL,
PRIMARY KEY  (login),
UNIQUE KEY login (login),
KEY login_2 (login),
KEY uid_2 (uid)
) TYPE=MyISAM;
