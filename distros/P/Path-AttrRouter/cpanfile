requires 'Class::Data::Inheritable';
requires 'Data::Util';
requires 'Module::Pluggable::Object';
requires 'Mouse', '1.05';
requires 'Text::SimpleTable', '1.1';
requires 'Try::Tiny';
requires 'perl', '5.008_001';

on configure => sub {
    requires 'CPAN::Meta';
    requires 'CPAN::Meta::Prereqs';
    requires 'Module::Build';
};

on test => sub {
    requires 'File::Temp';
    requires 'Test::More', '0.98';
    requires 'URI::Escape';
};
