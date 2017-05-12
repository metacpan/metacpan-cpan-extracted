--
-- Create a very simple database to hold book and author information
--
CREATE TABLE books (
        id          INTEGER PRIMARY KEY,
        title       TEXT ,
        rating      INTEGER
);
-- 'book_authors' is a many-to-many join table between books & authors
CREATE TABLE book_authors (
        book_id     INTEGER,
        author_id   INTEGER,
        PRIMARY KEY (book_id, author_id)
);
CREATE TABLE authors (
        id          INTEGER PRIMARY KEY,
        first_name  TEXT,
        last_name   TEXT
);
---
--- Load some sample data
---
INSERT INTO books VALUES (1, 'CCSP SNRS Exam Certification Guide', 5);
INSERT INTO books VALUES (2, 'TCP/IP Illustrated, Volume 1', 5);
INSERT INTO books VALUES (3, 'Internetworking with TCP/IP Vol.1', 4);
INSERT INTO books VALUES (4, 'Perl Cookbook', 5);
INSERT INTO books VALUES (5, 'Designing with Web Standards', 5);
INSERT INTO authors VALUES (1, 'Greg', 'Bastien');
INSERT INTO authors VALUES (2, 'Sara', 'Nasseh');
INSERT INTO authors VALUES (3, 'Christian', 'Degu');
INSERT INTO authors VALUES (4, 'Richard', 'Stevens');
INSERT INTO authors VALUES (5, 'Douglas', 'Comer');
INSERT INTO authors VALUES (6, 'Tom', 'Christiansen');
INSERT INTO authors VALUES (7, ' Nathan', 'Torkington');
INSERT INTO authors VALUES (8, 'Jeffrey', 'Zeldman');
INSERT INTO book_authors VALUES (1, 1);
INSERT INTO book_authors VALUES (1, 2);
INSERT INTO book_authors VALUES (1, 3);
INSERT INTO book_authors VALUES (2, 4);
INSERT INTO book_authors VALUES (3, 5);
INSERT INTO book_authors VALUES (4, 6);
INSERT INTO book_authors VALUES (4, 7);
INSERT INTO book_authors VALUES (5, 8);
