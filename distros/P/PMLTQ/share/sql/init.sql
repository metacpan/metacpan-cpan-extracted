--
-- init pgsql/pl used by initializing scripts
--
-- http://timmurphy.org/2011/08/27/create-language-if-it-doesnt-exist-in-postgresql/
CREATE OR REPLACE FUNCTION create_language_plpgsql()
RETURNS BOOLEAN AS $$
    CREATE LANGUAGE plpgsql;
    SELECT TRUE;
$$ LANGUAGE SQL;

SELECT CASE WHEN NOT
    (
        SELECT  TRUE AS exists
        FROM    pg_language
        WHERE   lanname = 'plpgsql'
        UNION
        SELECT  FALSE AS exists
        ORDER BY exists DESC
        LIMIT 1
    )
THEN
    create_language_plpgsql()
ELSE
    FALSE
END AS plpgsql_created;

DROP FUNCTION create_language_plpgsql();

--
-- aggregation function that concatenates fields
--
--
DROP AGGREGATE IF EXISTS concat_agg(text);

CREATE AGGREGATE concat_agg(
  basetype    = text,
  sfunc       = textcat,
  stype       = text,
  initcond    = ''
);

DROP TABLE IF EXISTS "#PML", "#PMLTYPES", "#PMLTABLES", "#PML_USR_REL";

CREATE TABLE "#PML" (
  "root" VARCHAR(32) UNIQUE,
  "schema_file" VARCHAR(128) UNIQUE,
  "data_dir" VARCHAR(128),
  "schema" TEXT,
  "last_idx" INT,
  "last_node_idx" INT,
  "flags" INT
);

CREATE TABLE "#PMLTYPES" (
  "type" VARCHAR(32) UNIQUE,
  "root" VARCHAR(32)
);

CREATE TABLE "#PMLTABLES" (
  "type" VARCHAR(128) UNIQUE,
  "table" VARCHAR(32)
);

CREATE TABLE "#PML_USR_REL" (
  "relname" VARCHAR(32) NOT NULL,
  "reverse" VARCHAR(32),
  "node_type" VARCHAR(64),
  "target_node_type" VARCHAR(64),
  "tbl" VARCHAR(32)
);
