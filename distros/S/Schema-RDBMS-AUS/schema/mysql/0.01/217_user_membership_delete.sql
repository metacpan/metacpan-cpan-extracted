
CREATE TRIGGER aus_user_membership_delete
    BEFORE DELETE
    ON aus_user_membership
    FOR EACH ROW
    BEGIN
        DECLARE done INT DEFAULT 0; --
        DECLARE a, b, c INT; --
        DECLARE cur1 CURSOR FOR
            SELECT
                BELOW.user_id, ABOVE.ancestor,
                (BELOW.degree + ABOVE.degree + 1)
            FROM   
                aus_user_ancestors AS BELOW,
                aus_user_ancestors AS ABOVE
            WHERE
                BELOW.ancestor = OLD.user_id
                AND ABOVE.user_id = OLD.member_of
            GROUP BY
                BELOW.user_id, ABOVE.ancestor,
                (BELOW.degree + ABOVE.degree + 1)
            HAVING
                COUNT(*) = 1
        ; --
        
        DECLARE CONTINUE HANDLER FOR SQLSTATE '02000' SET done = 1; --
    
        OPEN cur1; --
    
        REPEAT
            FETCH cur1 INTO a, b, c; --
            DELETE FROM aus_user_ancestors WHERE
                user_id = a AND ancestor = b AND degree = c; --
        UNTIL done END REPEAT; --  
    END
;
