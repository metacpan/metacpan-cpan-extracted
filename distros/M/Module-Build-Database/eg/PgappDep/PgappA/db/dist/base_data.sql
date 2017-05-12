--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;


--
-- Data for Name: person; Type: TABLE DATA; Schema: red; Owner: -
--

COPY person (id, first_name, last_name) FROM stdin;
\.


--
-- Name: person_id_seq; Type: SEQUENCE SET; Schema: red; Owner: -
--

SELECT pg_catalog.setval('person_id_seq', 1, false);


--
-- PostgreSQL database dump complete
--

