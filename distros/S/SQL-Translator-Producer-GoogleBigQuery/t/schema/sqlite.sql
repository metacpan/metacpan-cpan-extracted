
BEGIN TRANSACTION;

--
-- Table: author
--
CREATE TABLE author (
  id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  name VARCHAR(255)
);

CREATE UNIQUE INDEX name_uniq ON author (name);

--
-- Table: module
--
CREATE TABLE module (
  id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  name VARCHAR(255),
  author_id INTEGER
);

CREATE INDEX author_id_idx ON module (author_id);

COMMIT;

