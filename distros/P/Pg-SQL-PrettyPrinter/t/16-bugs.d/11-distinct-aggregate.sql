SELECT count(distinct x), array_agg( distinct id, ', ' ORDER BY id desc) FROM z
