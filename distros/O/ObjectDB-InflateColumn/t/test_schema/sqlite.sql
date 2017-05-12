PRAGMA foreign_keys=OFF;
BEGIN TRANSACTION;

CREATE TABLE `author` (
 `id` INTEGER PRIMARY KEY AUTOINCREMENT,
 `name` varchar(40) default '',
 `data` TEXT default 'null',
 `password` varchar(40) default '',
 UNIQUE(`name`)
);

COMMIT;
