--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET client_encoding = 'SQL_ASCII';
SET standard_conforming_strings = off;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET escape_string_warning = off;

--
-- Name: doo; Type: SCHEMA; Schema: -; Owner: -
--



SET search_path = doo, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: five; Type: TABLE; Schema: doo; Owner: -; Tablespace: 
--

CREATE TABLE five (
    five_col integer
);


--
-- Name: TABLE five; Type: COMMENT; Schema: doo; Owner: -
--

COMMENT ON TABLE five IS '2+3=5';


--
-- Name: COLUMN five.five_col; Type: COMMENT; Schema: doo; Owner: -
--

COMMENT ON COLUMN five.five_col IS 'this is a column for fives';


--
-- Name: number_four; Type: TABLE; Schema: doo; Owner: -; Tablespace: 
--

CREATE TABLE number_four (
    x integer,
    y integer,
    z integer,
    t integer
);


--
-- Name: TABLE number_four; Type: COMMENT; Schema: doo; Owner: -
--

COMMENT ON TABLE number_four IS 'this is table four';


--
-- Name: COLUMN number_four.x; Type: COMMENT; Schema: doo; Owner: -
--

COMMENT ON COLUMN number_four.x IS 'this is the x coordinate';


--
-- Name: COLUMN number_four.y; Type: COMMENT; Schema: doo; Owner: -
--

COMMENT ON COLUMN number_four.y IS 'this is the y coordinate';


--
-- Name: COLUMN number_four.t; Type: COMMENT; Schema: doo; Owner: -
--

COMMENT ON COLUMN number_four.t IS 'this is time!';


--
-- Name: one; Type: TABLE; Schema: doo; Owner: -; Tablespace: 
--

CREATE TABLE one (
    x integer
);


--
-- Name: three; Type: TABLE; Schema: doo; Owner: -; Tablespace: 
--

CREATE TABLE three (
    foo integer,
    bar integer,
    baz character varying
);


--
-- Name: TABLE three; Type: COMMENT; Schema: doo; Owner: -
--

COMMENT ON TABLE three IS 'this is the THREE table';


--
-- Name: COLUMN three.bar; Type: COMMENT; Schema: doo; Owner: -
--

COMMENT ON COLUMN three.bar IS 'this is the three.bar field';


--
-- Name: COLUMN three.baz; Type: COMMENT; Schema: doo; Owner: -
--

COMMENT ON COLUMN three.baz IS 'this is the bas field';


--
-- Name: two; Type: TABLE; Schema: doo; Owner: -; Tablespace: 
--

CREATE TABLE two (
    y character varying(20)
);


--
-- PostgreSQL database dump complete
--

