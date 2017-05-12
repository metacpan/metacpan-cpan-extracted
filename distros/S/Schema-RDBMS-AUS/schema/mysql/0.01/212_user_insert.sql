
CREATE TRIGGER aus_user_insert
    AFTER INSERT
    ON aus_user
    FOR EACH ROW
    BEGIN
        IF (
            SELECT COUNT(*) < 1 FROM aus_user_ancestors
                WHERE user_id = NEW.id AND ancestor = NEW.id
            )
        THEN
            INSERT INTO aus_user_ancestors VALUES (NEW.id, NEW.id, 0); --
        END IF; --
    END
;
