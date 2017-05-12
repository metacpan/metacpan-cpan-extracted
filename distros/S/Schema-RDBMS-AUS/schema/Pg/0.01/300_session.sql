
CREATE TABLE aus_session (
    id          varchar(128) NOT NULL PRIMARY KEY,
    created     TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    time_last   TIMESTAMP WITH TIME ZONE NULL,
    user_id     INT NULL,
    a_session   TEXT NULL,
    
    FOREIGN KEY (user_id)
        REFERENCES  aus_user (id)
        ON UPDATE CASCADE
        ON DELETE SET NULL
);
