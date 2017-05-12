CREATE OR REPLACE FUNCTION perl_version() RETURNS text LANGUAGE plperl AS $$

  return "Perl version running in postgres $^V";

$$;
