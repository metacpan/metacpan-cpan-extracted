CREATE TRIGGER aus_user_update
    AFTER UPDATE
    ON aus_user
    FOR EACH ROW
    BEGIN
        IF NEW.is_group != OLD.is_group THEN
            DO `Can not make a user a group or a group a user!`; --
        END IF; --
    END
;
