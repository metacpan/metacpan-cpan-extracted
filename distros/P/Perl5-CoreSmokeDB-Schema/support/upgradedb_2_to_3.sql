BEGIN;

CREATE OR REPLACE FUNCTION public.git_describe_as_plevel(character varying)
    RETURNS character varying
    LANGUAGE plpgsql
    IMMUTABLE
AS $function$
    DECLARE
        vparts varchar array [5];
        plevel varchar;
        clean  varchar;
    BEGIN
        SELECT regexp_replace($1, E'^v', '') INTO clean;
        SELECT regexp_replace(clean, E'-g\.\+$', '') INTO clean;

        SELECT regexp_split_to_array(clean, E'[\.\-]') INTO vparts;

        SELECT vparts[1] || '.' INTO plevel;
        SELECT plevel || lpad(vparts[2], 3, '0') INTO plevel;
        SELECT plevel || lpad(vparts[3], 3, '0') INTO plevel;
        if array_length(vparts, 1) = 3 then
            SELECT array_append(vparts, '0') INTO vparts;
        end if;
        if regexp_matches(vparts[4], 'RC') = array['RC'] then
            SELECT plevel || vparts[4] INTO plevel;
        else
            SELECT plevel || 'zzz' INTO plevel;
        end if;
        SELECT plevel || lpad(vparts[array_upper(vparts, 1)], 3, '0') INTO plevel;

        return plevel;
    END;
$function$ ;

ALTER TABLE report
 ADD COLUMN plevel varchar
  GENERATED ALWAYS AS (git_describe_as_plevel(git_describe)) STORED
            ;

DROP INDEX IF EXISTS report_plevel_idx;
CREATE INDEX report_plevel_idx
          ON report (plevel)
             ;

DROP INDEX IF EXISTS report_plevel_hostname_idx;
CREATE INDEX report_plevel_hostname_idx
          ON report (hostname, plevel)
              ;

DROP INDEX IF EXISTS report_smokedate_hostname_idx;
CREATE INDEX report_smokedate_hostname_idx
          ON report (hostname, smoke_date)
              ;

DROP INDEX IF EXISTS report_smokedate_plevel_hostname_idx;
CREATE INDEX report_smokedate_plevel_hostname_idx
          ON report (hostname, plevel, smoke_date)
             ;

UPDATE tsgateway_config
   SET value = '3'
 WHERE name = 'dbversion'
       ;

COMMIT;
