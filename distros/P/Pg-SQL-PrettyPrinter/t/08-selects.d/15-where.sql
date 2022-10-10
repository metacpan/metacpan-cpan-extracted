SELECT * FROM a WHERE b = c AND d < ( now() - '1 week'::pg_catalog.interval )
