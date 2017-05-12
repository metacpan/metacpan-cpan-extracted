
CREATE TABLE aus_user_membership (
    user_id     INT NOT NULL,
    member_of   INT NOT NULL,
    
    FOREIGN KEY (user_id)
        REFERENCES  aus_user (id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
        
    FOREIGN KEY (member_of)
        REFERENCES  aus_user (id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
        
    PRIMARY KEY (user_id, member_of)
) TYPE=InnoDB;
