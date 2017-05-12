requires 'perl', '5.008001';

requires 'Plack', '0';
requires 'OrePAN2', '0.16';

on configure => sub {
    requires 'CPAN::Meta';
    requires 'CPAN::Meta::Prereqs';
    requires 'Module::Build';
};

on 'test' => sub {
    requires 'HTTP::Request::Common';
    requires 'Test::More', '0.98';
    requires 'Test::Output', '1.02';
    requires 'File::pushd';
    requires 'File::Which';
};
