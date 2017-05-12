requires 'Encode';
requires 'Hash::MultiValue';
requires 'Plack::Request';
requires 'parent';
requires 'perl', '5.008001';

on configure => sub {
    requires 'CPAN::Meta';
    requires 'CPAN::Meta::Prereqs';
    requires 'Module::Build';
};

on test => sub {
    requires 'Test::More', '0.98';
    requires 'HTTP::Request';
    requires 'HTTP::Request::Common';
    requires 'Plack::Test';
};

on develop => sub {
    requires 'Test::LocalFunctions';
    requires 'Test::Perl::Critic';
    requires 'Test::Vars';
};
