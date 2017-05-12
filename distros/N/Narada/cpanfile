requires 'perl', '5.010001';

requires 'App::migrate', 'v0.2.0';
requires 'App::powerdiff';
requires 'DBI';
requires 'Export::Attrs';
requires 'File::Temp';
requires 'FindBin';
requires 'Getopt::Long';
requires 'List::Util';
requires 'Log::Fast';
requires 'MIME::Base64';
requires 'Path::Tiny', '0.065';
requires 'Time::HiRes';
requires 'Time::Local';
requires 'parent';
requires 'version', '0.77';

on configure => sub {
    requires 'CPAN::Meta', '2.150005';
    requires 'Devel::AssertOS';
    requires 'Module::Build', '0.28';
};

on test => sub {
    requires 'File::Copy::Recursive';
    requires 'Test::Database';
    requires 'Test::Differences';
    requires 'Test::Exception';
    requires 'Test::MockModule';
    requires 'Test::More', '0.96';
    requires 'Test::Output';
};

on develop => sub {
    requires 'Test::Distribution';
    requires 'Test::Perl::Critic';
};
