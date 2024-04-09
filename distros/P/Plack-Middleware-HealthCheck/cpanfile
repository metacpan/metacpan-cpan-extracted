requires 'JSON';
requires 'Plack::Middleware';
requires 'Plack::Request';
requires 'Plack::Util::Accessor';

on test => sub {
    requires 'HTTP::Request::Common';
    requires 'HealthCheck', '>= v1.9.1';
    requires 'Plack::Test';
    requires 'Test::Exception';
    requires 'Test2::Tools::Mock';
    requires 'Hash::MultiValue', '>= 0.1';
};

on develop => sub {
    requires 'Dist::Zilla::PluginBundle::Author::GSG';
};
