requires 'perl', '5.008001';
requires 'Class::Accessor::Lite';
requires 'SQL::Maker', '1.16';
requires 'SQL::QueryMaker', '0.02';
requires 'DBIx::Sunny', '>= 0.9993';

on 'test' => sub {
    requires 'Test::More', '0.98';
    requires 'Test::Exception', '0';
    requires 'Test::Time', '0';
    requires 'DBD::SQLite', '0';
    requires 'JSON', '0';
    requires 'Test::Requires';
    requires 'File::Temp';
    requires 'Mock::Quick';
    requires 'URI::db';
};

on 'develop' => sub {
    requires 'DBD::Pg';
    requires 'Test::PostgreSQL';
    requires 'DBD::mysql';
    requires 'Test::mysqld';
};
