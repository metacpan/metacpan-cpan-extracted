
CREATE OR REPLACE FUNCTION aus_user_insert ()
    RETURNS TRIGGER
    LANGUAGE PLPGSQL
    AS
'
    BEGIN
        INSERT INTO aus_user_ancestors
        SELECT NEW.id, NEW.id, 0
            WHERE (NEW.id, NEW.id) NOT IN 
                (SELECT user_id,ancestor FROM aus_user_ancestors)
            ; --
        
        RETURN NEW; --
    END
';
