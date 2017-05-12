CREATE TABLE users (
    username varchar(255) PRIMARY KEY,
    password varchar(255) NOT NULL,
    created integer,
    active boolean default TRUE
);

INSERT INTO users VALUES ("test", "pass", "2009-01-06T17:44:38", 1);
