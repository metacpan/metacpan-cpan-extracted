CREATE TRIGGER aus_user_delete
    BEFORE DELETE
    ON aus_user
    FOR EACH ROW
    BEGIN
        DELETE FROM aus_user_membership
            WHERE user_id = OLD.id OR member_of = OLD.id; --
            
        DELETE FROM aus_user_ancestors
            WHERE user_id = OLD.id AND ancestor = OLD.id; --
    END
;
