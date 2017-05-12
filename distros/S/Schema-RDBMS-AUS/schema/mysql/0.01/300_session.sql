
CREATE TABLE aus_session (
    id          varchar(128) NOT NULL PRIMARY KEY,
    created     TIMESTAMP NOT NULL DEFAULT now(),
    time_last   TIMESTAMP NULL,
    user_id     INT NULL,
    a_session   BLOB NULL,
    
    FOREIGN KEY (user_id)
        REFERENCES  aus_user (id)
        ON UPDATE CASCADE
        ON DELETE SET NULL
) TYPE=InnoDB;
