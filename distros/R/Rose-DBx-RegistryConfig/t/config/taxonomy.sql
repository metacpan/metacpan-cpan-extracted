/* taxonomy.sql */
BEGIN TRANSACTION;
DROP TABLE IF EXISTS species;
CREATE TABLE species (
    id              int,
    name            varchar(25),
    common_name     varchar(25)
);
INSERT INTO "species" VALUES (1,'Accipiter striatus','Sharp-shinned Hawk');
INSERT INTO "species" VALUES (2,'Aimophila aestivalis',"Bachman's Sparrow");
INSERT INTO "species" VALUES (3,'Aneides aeneus','Green Salamander');
INSERT INTO "species" VALUES (4,'Corynorhinus rafinesquii','Eastern Big-eared Bat');
INSERT INTO "species" VALUES (5,'Gyrinophilus palleucus','Tennessee Cave Salamander');
INSERT INTO "species" VALUES (6,'Haliaeetus leucocephalus','Bald Eagle');
INSERT INTO "species" VALUES (7,'Hemidactylium scutatum','Four-toed Salamander');
COMMIT;
