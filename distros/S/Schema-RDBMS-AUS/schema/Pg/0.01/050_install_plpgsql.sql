
CREATE OR REPLACE FUNCTION make_plpgsql () RETURNS bool AS
'
    CREATE TRUSTED LANGUAGE "plpgsql" HANDLER "plpgsql_call_handler"; --
    SELECT true; --
' LANGUAGE SQL;

SELECT CASE WHEN
    (SELECT COUNT(oid) > 0 FROM pg_language WHERE lanname = 'plpgsql')
    THEN false ELSE
    (SELECT make_plpgsql())
    END
;

DROP FUNCTION make_plpgsql ();
