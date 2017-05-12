
CREATE TABLE aus_user_flags (
    user_id     INT NOT NULL,
    flag_name   VARCHAR(128) NOT NULL,
    enabled     BOOL NOT NULL DEFAULT TRUE,
    
    FOREIGN KEY (user_id)
        REFERENCES aus_user (id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
        
    FOREIGN KEY (flag_name)
        REFERENCES aus_flag (name)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
        
    PRIMARY KEY (user_id, flag_name)
);
