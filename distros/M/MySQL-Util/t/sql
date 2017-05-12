-- 
-- TABLE: depth_0a 
--

CREATE TABLE depth_0a(
    depth_0a_id    INT    NOT NULL,
    PRIMARY KEY (depth_0a_id)
)ENGINE=INNODB
;

-- 
-- TABLE: depth_0b 
--

CREATE TABLE depth_0b(
    depth_0b_id    INT    NOT NULL,
    PRIMARY KEY (depth_0b_id)
)ENGINE=INNODB
;



-- 
-- TABLE: depth_1a 
--

CREATE TABLE depth_1a(
    depth_1a_id    INT    NOT NULL,
    depth_0a_id    INT    NOT NULL,
    PRIMARY KEY (depth_1a_id), 
    FOREIGN KEY (depth_0a_id)
    REFERENCES depth_0a(depth_0a_id)
)ENGINE=INNODB
;



-- 
-- TABLE: depth_2a 
--

CREATE TABLE depth_2a(
    depth_1a_id    INT    NOT NULL,
    depth_0b_id    INT    NOT NULL,
    PRIMARY KEY (depth_1a_id, depth_0b_id), 
    FOREIGN KEY (depth_1a_id)
    REFERENCES depth_1a(depth_1a_id),
    FOREIGN KEY (depth_0b_id)
    REFERENCES depth_0b(depth_0b_id)
)ENGINE=INNODB
;

--
-- TABLE: depth_3a
--
CREATE TABLE depth_3a(
    depth_3a_id     INT     AUTO_INCREMENT,
    depth_1a_id    INT    NOT NULL,
    PRIMARY KEY (depth_3a_id),
    FOREIGN KEY (depth_1a_id) REFERENCES depth_2a(depth_1a_id)
)ENGINE=INNODB
;

-- 
-- TABLE: table_a 
--

CREATE TABLE table_a(
    table_a_id    INT    AUTO_INCREMENT,
    name          INT,
    tester		  varchar(20) NULL,
    PRIMARY KEY (table_a_id), 
    UNIQUE INDEX table_a_ak(name)
 )ENGINE=INNODB
;



-- 
-- TABLE: table_b 
--

CREATE TABLE table_b(
    table_b_id    INT    AUTO_INCREMENT,
    name          INT,
    table_a_id    INT    NOT NULL,
    col1          INT,
    col2          INT,
    PRIMARY KEY (table_b_id), 
    UNIQUE INDEX table_b_ak(name, table_a_id),
    INDEX table_b_fk(table_a_id),
    INDEX table_b_idx(col1),
    UNIQUE INDEX table_b_ak2(col2), 
    CONSTRAINT table_b_fc FOREIGN KEY (table_a_id)
    REFERENCES table_a(table_a_id)
)ENGINE=INNODB
;



-- 
-- TABLE: table_c 
--

CREATE TABLE table_c(
    table_c_id    INT    NOT NULL,
    PRIMARY KEY (table_c_id)
)ENGINE=INNODB
;



-- 
-- TABLE: table_d 
--

CREATE TABLE table_d(
    col1    INT
)ENGINE=INNODB
;



