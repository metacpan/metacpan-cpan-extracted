requires 'perl', '5.008001';
requires 'Class::Accessor::Lite';
requires 'SQL::Maker', '1.16';
requires 'SQL::QueryMaker', '0.02';
requires 'DBIx::Sunny';

on 'test' => sub {
    requires 'Test::More', '0.98';
    requires 'Test::Time', '0';
    requires 'DBD::SQLite', '0';
    requires 'JSON', '0';
    requires 'Test::Requires';
    requires 'File::Temp';
    requires 'Mock::Quick'
};

on 'develop' => sub {
    requires 'Test::PostgreSQL';
    requires 'Test::mysqld';
};
