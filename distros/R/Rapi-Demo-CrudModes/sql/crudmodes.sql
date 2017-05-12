
DROP TABLE IF EXISTS [alpha];
CREATE TABLE [alpha] (
  [id]        INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  [string1]   varchar(32) DEFAULT NULL,
  [string2]   varchar(64) DEFAULT NULL,
  [number]    float DEFAULT NULL,
  [bool]      boolean NOT NULL default 0,
  [date]      date DEFAULT NULL
);

DROP TABLE IF EXISTS [bravo];
CREATE TABLE [bravo] (
  [id]       INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  [title]    varchar(32) UNIQUE NOT NULL,
  [price]    decimal(8,2) DEFAULT NULL
);

DROP TABLE IF EXISTS [bravo_note];
CREATE TABLE   [bravo_note] (
  [id]         INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  [bravo_id]   INTEGER NOT NULL,
  [text]       varchar(128) DEFAULT NULL,
  [timestamp]  datetime DEFAULT current_timestamp,
  FOREIGN KEY ([bravo_id]) REFERENCES [bravo] ([id]) 
   ON DELETE CASCADE ON UPDATE CASCADE
);
