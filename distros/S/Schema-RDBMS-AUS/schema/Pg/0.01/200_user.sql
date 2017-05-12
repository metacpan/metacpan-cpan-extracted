
CREATE TABLE aus_user (
    id              SERIAL NOT NULL PRIMARY KEY,
    name            VARCHAR(64) NOT NULL,
    password        VARCHAR(128) NULL,              -- Null = Disabled Account
    password_crypt  VARCHAR(32) NOT NULL,
    is_group        BOOL NOT NULL DEFAULT FALSE,
    
    time_used       TIMESTAMP WITH TIME ZONE NULL,
    
    FOREIGN KEY     (password_crypt)
        REFERENCES      aus_password_crypt (id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);

CREATE UNIQUE INDEX aus_user_name_key ON aus_user (name);
