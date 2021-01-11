configure_requires 'ExtUtils::MakeMaker' => '6.64';
configure_requires 'Module::CPANfile'    => '1.1004';

requires 'OpenTracing::GlobalTracer'         => '0.04';
requires 'OpenTracing::Implementation'       => 'v0.31.0';
requires 'OpenTracing::Implementation::NoOp' => 'v0.72.1';
requires 'OpenTracing::Manual'               => '0.05';

feature 'instrumentation' => 'Making instrumenting code easier' => sub {
    requires 'OpenTracing::AutoScope' => 'v0.106.6';
    requires 'OpenTracing::WrapScope' => 'v0.106.6';
};

feature 'development' => 'Development of new integrations or implementations' => sub {
    requires 'OpenTracing::Implementation::Test' => 'v0.102.1';
    requires 'OpenTracing::Interface'            => 'v0.205.0';
    requires 'OpenTracing::Types'                => 'v0.205.0';
    requires 'OpenTracing::Role'                 => 'v0.84.0';
    requires 'Test::OpenTracing::Integration'    => 'v0.102.1';
};

feature 'datadog' => 'DataDog implementation' => sub {
    requires 'OpenTracing::Implementation::DataDog'           => 'v0.42.1';
    requires 'CGI::Application::Plugin::OpenTracing::DataDog' => 'v0.1.0';
};

feature 'integrations' => 'Extra integrations' => sub {
    requires 'DBIx::OpenTracing'                     => 'v0.1.0';
    requires 'CGI::Application::Plugin::OpenTracing' => 'v0.103.3';
    requires 'Log::Log4perl::OpenTracing'            => 'v0.1.2';
};

on test => sub {
    requires 'Test::More';
};
