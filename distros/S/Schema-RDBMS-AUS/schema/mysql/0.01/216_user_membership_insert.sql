CREATE TRIGGER aus_user_membership_insert
    AFTER INSERT
    ON aus_user_membership
    FOR EACH ROW
    BEGIN
        IF (
            SELECT COUNT(*) > 0 FROM aus_user_ancestors
                WHERE
                    aus_user_ancestors.user_id = NEW.member_of
                AND
                    aus_user_ancestors.ancestor = NEW.user_id
            )
        THEN
            DO `Circular membership: Group ancestor is already a member of new group`; --
        END IF; --
        
        IF (SELECT NOT is_group FROM aus_user WHERE id = NEW.member_of) THEN
            DO `User #? is not a group!`; --
        END IF; --
    
        INSERT INTO aus_user_ancestors
            SELECT  NEW.user_id, ancestor, degree + 1
            FROM    aus_user_ancestors WHERE user_id = NEW.member_of
                UNION
            SELECT  user_id, NEW.member_of, degree + 1
            FROM    aus_user_ancestors WHERE ancestor = NEW.user_id
        ; --
    END
;
