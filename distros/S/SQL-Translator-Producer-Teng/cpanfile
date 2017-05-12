requires 'DBI';
requires 'Data::Section::Simple';
requires 'SQL::Translator', '0.11017';
requires 'Text::Xslate';
requires 'perl', '5.008001';

on configure => sub {
    requires 'CPAN::Meta';
    requires 'CPAN::Meta::Prereqs';
    requires 'Module::Build';
};

on test => sub {
    requires 'File::Temp';
    requires 'Test::More', '0.98';
    requires 'Test::Requires';
    requires 'parent';

    recommends 'Teng';
    recommends 'DBD::SQLite';
};
