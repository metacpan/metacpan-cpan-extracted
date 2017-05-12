
CREATE TABLE aus_user_log (
    id          SERIAL NOT NULL PRIMARY KEY,
    user_id     INT NOT NULL,
    event_time  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    event       VARCHAR(128) NOT NULL,
    data        TEXT NULL,
    
    FOREIGN KEY (user_id)
        REFERENCES aus_user (id)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

CREATE INDEX aus_user_log__event ON aus_user_log (event);
CREATE INDEX aus_user_log__event_time ON aus_user_log (event_time);
CREATE INDEX aus_user_log__user_id ON aus_user_log (user_id);
