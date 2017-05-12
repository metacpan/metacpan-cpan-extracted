DROP TABLE IF EXISTS members;    

CREATE TABLE members      (    
    id      INT UNSIGNED    NOT NULL AUTO_INCREMENT PRIMARY KEY,
    email   VARCHAR(255)    NOT NULL,
    UNIQUE  ( email )
) TYPE = InnoDB;
