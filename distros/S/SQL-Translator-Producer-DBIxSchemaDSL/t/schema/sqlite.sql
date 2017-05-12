
BEGIN TRANSACTION;

--
-- Table: author
--
CREATE TABLE author (
  id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  name VARCHAR(255),
  age TINYINT NOT NULL DEFAULT 0,
  message TEXT NOT NULL
);

CREATE UNIQUE INDEX name_uniq ON author (name);

--
-- Table: module
--
CREATE TABLE module (
  id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  name VARCHAR(255),
  author_id INTEGER,
  FOREIGN KEY (author_id) REFERENCES author(id)
);

CREATE INDEX author_id_idx ON module (author_id);

COMMIT;

