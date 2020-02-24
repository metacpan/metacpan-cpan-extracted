use <: $module_name ~ "::Const qw[]" :>;

<<'SQL'
    CREATE EXTENSION IF NOT EXISTS "pgcrypto";

    CREATE EXTENSION IF NOT EXISTS "timescaledb" CASCADE;

    CREATE EXTENSION IF NOT EXISTS "pg_hashids";
SQL
