requires 'perl', '5.008001';

requires 'Otogiri', '0.09';
requires 'Otogiri::Plugin';

on 'test' => sub {
    requires 'Test::More', '0.98';
    requires 'Test::Requires';
};

on 'develop' => sub {
    requires 'Test::mysqld';
    requires 'Test::PostgreSQL';
};
