
SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;





SET default_tablespace = '';

SET default_with_oids = false;


CREATE TABLE person (
    id integer NOT NULL,
    first_name character varying(120),
    last_name character varying(120)
);



CREATE SEQUENCE person_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



ALTER SEQUENCE person_id_seq OWNED BY person.id;



ALTER TABLE ONLY person ALTER COLUMN id SET DEFAULT nextval('person_id_seq'::regclass);



ALTER TABLE ONLY person
    ADD CONSTRAINT person_first_name_last_name_key UNIQUE (first_name, last_name);



