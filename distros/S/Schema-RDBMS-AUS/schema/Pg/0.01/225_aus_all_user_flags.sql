CREATE OR REPLACE VIEW 
    aus_all_user_flags
AS
    SELECT
        aus_user_ancestors.user_id AS user_id,
        flag_name,
        CASE WHEN
            substr(
                MIN(
                    lpad('0',5,degree::text) ||
                    (CASE WHEN enabled THEN '1' ELSE '0' END)
                ),
                6
            )::int
            > 0
            THEN true ELSE false
        END
        AS enabled
    FROM
        aus_user_flags
    JOIN
        aus_user_ancestors
    ON
        aus_user_ancestors.ancestor = aus_user_flags.user_id
    GROUP BY
        aus_user_ancestors.user_id,
        aus_user_flags.flag_name
;
