DROP TABLE IF EXISTS report       CASCADE;
DROP TABLE IF EXISTS config       CASCADE;
DROP TABLE IF EXISTS result       CASCADE;
DROP TABLE IF EXISTS failure      CASCADE;
DROP TABLE IF EXISTS smoke_config CASCADE;

CREATE TABLE smoke_config
           ( id      serial not null  PRIMARY KEY
           , md5     varchar not null UNIQUE
           , config  varchar
           ) ;

CREATE TABLE report
           ( id              serial not null PRIMARY KEY
           , sconfig_id      int REFERENCES smoke_config (id)

-- report
           , duration         int                 -- 35464
           , config_count     int                 -- 32
           , reporter         varchar             -- "abe.timmerman@test-smoke.org"
           , reporter_version varchar             -- "0.050"
           , smoke_perl       varchar             -- 5.10.1
           , smoke_revision   varchar             -- 1285
           , smoke_version   varchar              -- 1.44
           , smoker_version  varchar              -- 0.045
-- id
           , smoke_date      timestamp with time zone not null -- 2011-04-14 21:20:43Z
           , perl_id         varchar not null                  -- "5.14.0"
           , git_id          varchar not null                  -- "b4ffc3db31e268adb50c44bab9b628dc619f1e83"
           , git_describe    varchar not null                  -- 5.13.11-1423-ga4f23763
           , applied_patches varchar                           -- -
--node
           , hostname        varchar not null         -- "smokebox"
           , architecture    varchar not null         -- "ia64"
           , osname          varchar not null         -- "HP-UX"
           , osversion       varchar not null         -- "B.11.31/64"
           , cpu_count       varchar                  -- "1 [2 cores]"
           , cpu_description varchar                  -- "Itanium 2 9100/1710"
           , username        varchar                  -- "tux"
-- build
           , test_jobs       varchar                  -- NULL
           , lc_all          varchar                  -- "en_US.utf8"
           , lang            varchar                  -- NULL
           , user_note       varchar                  -- "logs: http://blah.bla/smokelogs/"
           , manifest_msgs   bytea                    -- "..."
           , compiler_msgs   bytea                    -- "..."
           , skipped_tests   varchar                  -- "..."
           , log_file        bytea
           , out_file        bytea
           , harness_only    varchar                  -- "1"
           , harness3opts    varchar                  -- "j5"
           , summary         varchar not null         -- "FAIL(F)"
           , UNIQUE(git_id, smoke_date, duration, hostname, architecture)
           ) ;

CREATE TABLE config
           ( id        serial not null PRIMARY KEY
           , report_id int    not null REFERENCES report (id)
--config
           , arguments varchar not null     -- "-Duse64bitall -DDEBUGGING"
           , debugging varchar not null     -- "D/N"
           , started   timestamp with time zone
           , duration  int
           , cc        varchar              -- "cc"
           , ccversion varchar              -- "B3910B"
           ) ;

CREATE TABLE result
           ( id            serial  not null PRIMARY KEY
           , config_id     int     not null REFERENCES config (id)
           , io_env        varchar not null       -- "perlio"
           , locale        varchar                -- "nl_NL.utf8"
           , summary       varchar not null       -- "F"
           , statistics    varchar                -- "Files=1802, Tests=349808, .."
           , stat_cpu_time float                  -- 1187.68
           , stat_tests    int                    -- 520371
           ) ;

CREATE TABLE failure
           ( id        serial not null PRIMARY KEY
           , test      varchar not null
           , status    varchar not null
           , extra     varchar
           , UNIQUE(test, status, extra)
           ) ;

CREATE TABLE failures_for_env
           ( result_id int not null REFERENCES result (id)
           , failure_id int not null REFERENCES failure (id)
           , UNIQUE(result_id, failure_id)
           ) ;
