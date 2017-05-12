requires 'DBI';
requires 'DBIx::Inspector';
requires 'List::MoreUtils';
requires 'Otogiri', '0.06';
requires 'Otogiri::Plugin', '0.02';
requires 'perl', '5.008005';
requires 'parent';

on configure => sub {
    requires 'CPAN::Meta';
    requires 'CPAN::Meta::Prereqs';
    requires 'Module::Build';
};

on test => sub {
    requires 'Test::Differences';
    requires 'Test::More';
    requires 'Test::Requires';
    requires 'DBD::SQLite';
};

on develop => sub {
    requires 'Test::mysqld';
    requires 'Test::PostgreSQL';
};
