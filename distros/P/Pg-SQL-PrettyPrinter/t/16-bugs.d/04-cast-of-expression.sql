SELECT (data->>'timestamp')::timestamptz, (1 = 1 or 2 = 2)::int4 from z;
