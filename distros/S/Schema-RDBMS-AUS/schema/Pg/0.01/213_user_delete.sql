
CREATE OR REPLACE FUNCTION aus_user_delete ()
    RETURNS TRIGGER
    LANGUAGE PLPGSQL
    AS
'
    BEGIN
    
        DELETE FROM aus_user_membership
            WHERE user_id = OLD.id OR member_of = OLD.id; --
            
        DELETE FROM aus_user_ancestors
            WHERE user_id = OLD.id AND ancestor = OLD.id; --

        RETURN  OLD; --
    END
';
