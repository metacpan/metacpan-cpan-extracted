
CREATE TABLE aus_user_ancestors (
    user_id     INT NOT NULL,
    ancestor    INT NOT NULL,
    degree      INT NOT NULL,
    
    FOREIGN KEY (user_id)
        REFERENCES      aus_user (id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
        
    FOREIGN KEY (ancestor)
        REFERENCES      aus_user (id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    
    PRIMARY KEY (user_id, ancestor, degree)
) TYPE=InnoDB;

CREATE INDEX aus_user_ancestors_ancestor ON aus_user_ancestors (ancestor);
