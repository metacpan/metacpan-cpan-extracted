
SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;






CREATE FUNCTION perl_version() RETURNS text
    LANGUAGE plperl
    AS $_$

  return "Perl version running in postgres $^V";

$_$;



