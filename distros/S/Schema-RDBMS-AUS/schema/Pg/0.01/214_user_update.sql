CREATE OR REPLACE FUNCTION aus_user_update ()
    RETURNS TRIGGER
    LANGUAGE PLPGSQL
    AS
'
    BEGIN
        IF NEW.is_group != OLD.is_group THEN
            RAISE EXCEPTION
                ''Can not make a user a group or a group a user!''; --
        END IF; --
        
        RETURN NEW; --
    END; --
';
