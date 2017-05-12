CREATE OR REPLACE FUNCTION aus_user_membership_insert ()
    RETURNS TRIGGER
    LANGUAGE PLPGSQL
    AS
'
    BEGIN
        IF (
            SELECT COUNT(*) > 0 FROM aus_user_ancestors
                WHERE
                    aus_user_ancestors.user_id = NEW.member_of
                AND
                    aus_user_ancestors.ancestor = NEW.user_id
            )
        THEN
            RAISE EXCEPTION
                ''Circular membership: Group % is already a member of %'',
                NEW.member_of, NEW.user_id; --
        END IF; --
        
        IF (SELECT NOT is_group FROM aus_user WHERE id = NEW.member_of) THEN
            RAISE EXCEPTION ''User #% is not a group!'', NEW.member_of; --
        END IF; --
    
        INSERT INTO aus_user_ancestors
            SELECT  NEW.user_id, ancestor, degree + 1
            FROM    aus_user_ancestors WHERE user_id = NEW.member_of
                UNION
            SELECT  user_id, NEW.member_of, degree + 1
            FROM    aus_user_ancestors WHERE ancestor = NEW.user_id
        ; --

        RETURN NEW; --
    END
';
