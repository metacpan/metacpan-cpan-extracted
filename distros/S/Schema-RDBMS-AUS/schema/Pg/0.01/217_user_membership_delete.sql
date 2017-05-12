
CREATE OR REPLACE FUNCTION aus_user_membership_delete ()
    RETURNS TRIGGER
    LANGUAGE PLPGSQL
    AS
'
    BEGIN
        DELETE FROM aus_user_ancestors
            WHERE
                (user_id, ancestor, degree)
                IN
                (
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
                ); --

        RETURN OLD; --
    END
';
