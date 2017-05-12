requires 'perl', '5.008005';
requires 'strict';
requires 'warnings';
requires 'Plack::Middleware::StackTrace';
requires 'Plack::App::SourceViewer';
requires 'Plack::Util';
requires 'Plack::Util::Accessor';

on 'test' => sub {
    requires 'Test::More', '0.88';
    requires 'HTTP::Request::Common';
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
};
