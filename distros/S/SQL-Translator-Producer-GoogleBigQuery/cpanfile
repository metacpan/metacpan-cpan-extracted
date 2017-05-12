requires 'DBI';
requires 'JSON::PP';
requires 'perl', '5.008001';

on configure => sub {
    requires 'Module::Build::Tiny', '0.035';
};

on test => sub {
    requires 'File::Temp';
    requires 'SQL::Translator';
    requires 'Test::More', '0.98';
};
