requires 'perl', '5.008005';
requires 'strict';
requires 'warnings';
requires 'Plack::Request';
requires 'Plack::Middleware';
requires 'Plack::Util::Accessor';
requires 'ShellQuote::Any', '0.04';

on 'test' => sub {
    requires 'Test::More', '0.88';
    requires 'Plack::Builder';
    requires 'HTTP::Request::Common';
    requires 'LWP::UserAgent';
    requires 'Plack::Test';
};

on 'configure' => sub {
    requires 'Module::Build' , '0.40';
    requires 'Module::Build::Pluggable';
    requires 'Module::Build::Pluggable::CPANfile';
};

on 'develop' => sub {
    recommends 'Test::Perl::Critic';
    recommends 'Test::Pod::Coverage';
    recommends 'Test::Pod';
    recommends 'Test::NoTabs';
    recommends 'Test::Perl::Metrics::Lite';
    recommends 'Test::Vars';
    recommends 'Test::File::Find::Rule';
};
