CREATE VIEW 
    aus_all_user_flags
AS
    SELECT
        aus_user_ancestors.user_id AS user_id,
        flag_name,
        CASE WHEN
            substr(
                MIN(
                    CONCAT(
                        lpad(CAST(degree AS char),5,'0'),
                        IF(enabled, '1', '0')
                    )
                ),
                6
            )
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
