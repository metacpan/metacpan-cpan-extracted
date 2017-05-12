requires 'DBI';
requires 'DBIx::Inspector';
requires 'Getopt::Long';
requires 'Moo';
requires 'Pod::Usage';
requires 'Term::ReadKey';
requires 'perl', '5.008001';

on configure => sub {
    requires 'Module::Build::Tiny', '0.035';
};

on test => sub {
    requires 'Test::More', '0.98';
};

on develop => sub {
    requires 'Test::mysqld';
};
