
-- create_tablestest1.sql

DROP DATABASE pg_bulkcopy_test ;

CREATE DATABASE pg_bulkcopy_test
  WITH OWNER = postgres
       CONNECTION LIMIT = -1;

COMMENT ON SCHEMA public IS 'standard public schema';
SET search_path = public, pg_catalog;
SET default_tablespace = '';
SET default_with_oids = false;

\c pg_bulkcopy_test ;

CREATE TABLE testing (
    flavor character varying,
    keyseq bigint NOT NULL,
    somebgnt bigint,
    sumsmlnt smallint,
    ancient date,
    whn time without time zone,
    threekar character(3),
    ntnnl character varying NOT NULL,
    bgtxt text
);
CREATE TABLE millions (
    keyseq bigint NOT NULL,
    bgnt bigint,
    smlnt smallint,
    word character varying NOT NULL
);

ALTER TABLE ONLY testing
    ADD CONSTRAINT tpkkey PRIMARY KEY (keyseq);
ALTER TABLE ONLY millions
    ADD CONSTRAINT mpkkey PRIMARY KEY (keyseq);
REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;
