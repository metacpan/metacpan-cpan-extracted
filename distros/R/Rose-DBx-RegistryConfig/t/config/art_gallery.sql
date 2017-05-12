/* art_gallery.sql */
BEGIN TRANSACTION;
DROP TABLE IF EXISTS artist;
CREATE TABLE artist (
    id          int,
    name        varchar(25),
    rating      int
);
INSERT INTO "artist" VALUES (1,'artist_one',  1);
INSERT INTO "artist" VALUES (2,'artist_two',  2);
INSERT INTO "artist" VALUES (3,'artist_three',3);
COMMIT;
