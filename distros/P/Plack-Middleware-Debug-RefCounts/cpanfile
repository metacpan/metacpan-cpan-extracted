requires 'perl', '5.10.1';
requires 'strict';
requires 'warnings';
requires 'parent';
requires 'namespace::clean';

requires 'Plack::Middleware::Debug::Base';

requires 'Data::Dumper';
requires 'Devel::Gladiator';
requires 'Env';
requires 'Scalar::Util';

on test => sub {
    requires 'Capture::Tiny';
    requires 'HTTP::Request::Common';
    requires 'Plack::Builder';
    requires 'Plack::Middleware::Debug';
    requires 'Plack::Test';
    requires 'Test::More';
};

on develop => sub {
    requires 'Dist::Zilla::PluginBundle::Author::GSG';
    requires 'File::Find';
    requires 'Module::Metadata', '1.00';
    requires 'Test2::Bundle::More';
    requires 'Test2::Require::AuthorTesting';
    requires 'Test::CPAN::Changes';
    requires 'Test::Pod', '1.51';
    requires 'Test::Pod::Coverage', '1.10';
    requires 'Test::Strict';
    requires 'Test::Version', '2.00';
};
