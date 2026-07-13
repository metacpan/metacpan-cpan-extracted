PRAGMA foreign_keys=OFF;
BEGIN TRANSACTION;
CREATE TABLE account (
   id INTEGER PRIMARY KEY,
   username TEXT NOT NULL UNIQUE,
   userpass TEXT,
   fullname TEXT,
   groups TEXT
);
INSERT INTO account
   VALUES (
      1,
      'baz',
      '$argon2id$v=19$m=262144,t=3,p=1$v6T3qPwPgqgcnOHhHysUJQ$TIezI1yuIw+XAuX+IrSWPGvYyvrHTBwS9ppYyy611pI',
      'Baz de Galook',
      'this other'
   );
COMMIT;
