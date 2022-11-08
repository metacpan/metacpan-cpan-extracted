SELECT
    case
    WHEN COUNT(*) FILTER (WHERE col_state = 2) = COUNT(col_id) THEN true
    WHEN COUNT(*) FILTER (WHERE col_state = 3) > 0 THEN false
    ELSE null end AS col_alias
FROM my_table
