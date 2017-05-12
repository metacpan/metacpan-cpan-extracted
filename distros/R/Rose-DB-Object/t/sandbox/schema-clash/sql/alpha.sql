DROP TABLE IF EXISTS friends;
DROP TABLE IF EXISTS members;

CREATE TABLE members      (    
    id          INT UNSIGNED    NOT NULL AUTO_INCREMENT PRIMARY KEY,
    user        VARCHAR(255)    NOT NULL,
    UNIQUE ( user )
) TYPE = InnoDB;

CREATE TABLE friends (
    id          INT UNSIGNED    NOT NULL AUTO_INCREMENT PRIMARY KEY,
    member_id   INT UNSIGNED    NOT NULL,
    reference   VARCHAR(255)    NOT NULL,    
    FOREIGN KEY ( member_id ) REFERENCES members ( id ) ON DELETE CASCADE
) Engine = InnoDB;
