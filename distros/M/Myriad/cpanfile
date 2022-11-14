# Syntax
requires 'mro';
requires 'indirect';
requires 'multidimensional';
requires 'bareword::filehandles';
requires 'XS::Parse::Keyword', '>= 0.27';
requires 'Syntax::Keyword::Dynamically', '>= 0.10';
requires 'Syntax::Keyword::Try', '>= 0.27';
requires 'Syntax::Keyword::Defer', '>= 0.07';
requires 'Syntax::Keyword::Match', '>= 0.09';
requires 'Syntax::Operator::Equ', '>= 0.04';
requires 'Future', '>= 0.49';
requires 'Future::Queue';
requires 'Future::AsyncAwait', '>= 0.59';
requires 'Future::IO', '>= 0.11';
requires 'XS::Parse::Sublike', '>= 0.16';
requires 'Object::Pad', '>= 0.71';
requires 'Role::Tiny', '>= 2.002004';
# Streams
requires 'Ryu', '>= 3.002';
requires 'Ryu::Async', '>= 0.020';
# IO::Async
requires 'Heap', '>= 0.80';
requires 'IO::Async', '>= 0.802';
requires 'IO::Async::Notifier', '>= 0.802';
requires 'IO::Async::Test', '>= 0.802';
requires 'IO::Async::SSL', '>= 0.23';
# Functionality
requires 'curry', '>= 2.000001';
requires 'Log::Any', '>= 1.710';
requires 'Log::Any::Adapter', '>= 1.710';
requires 'Config::Any', '>= 0.32';
requires 'YAML::XS', '>= 0.85';
requires 'Metrics::Any', '>= 0.08';
requires 'OpenTracing::Any', '>= 1.006';
requires 'JSON::MaybeUTF8', '>= 2.000';
requires 'Unicode::UTF8';
requires 'Time::Moment', '>= 0.44';
requires 'Sys::Hostname';
requires 'Pod::Simple::Text';
requires 'Scope::Guard';
requires 'Check::UnitCheck';
requires 'Class::Method::Modifiers';
requires 'Module::Load';
requires 'Module::Runtime';
requires 'Module::Pluggable::Object';
requires 'Math::Random::Secure';
requires 'Getopt::Long';
requires 'Pod::Usage';
requires 'List::Util', '>= 1.63';
requires 'List::Keywords', '>= 0.08';
# Integration
requires 'Net::Async::OpenTracing', '>= 1.001';
requires 'Log::Any::Adapter::OpenTracing', '>= 0.001';
requires 'Metrics::Any::Adapter::Statsd', '>= 0.03';
# Transport
requires 'Net::Async::Redis', '>= 3.022';
requires 'Net::Async::HTTP', '>= 0.48';
requires 'Net::Async::HTTP::Server', '>= 0.13';
# Introspection
requires 'Devel::MAT::Dumper';

# Things that may move out
recommends 'Term::ReadLine';
recommends 'Linux::Inotify2';

on 'test' => sub {
    requires 'Test::More', '>= 0.98';
    requires 'Test::Deep', '>= 1.130';
    requires 'Test::Fatal', '>= 0.014';
    requires 'Test::MemoryGrowth', '>= 0.03';
    requires 'Log::Any::Adapter::TAP';
    requires 'Log::Any::Test';
    requires 'Test::CheckDeps';
    requires 'Test::NoTabs';
    requires 'Test::MockModule';
    requires 'Test::MockObject';
};

on 'develop' => sub {
    requires 'Devel::Cover::Report::Coveralls', '>= 0.11';
    requires 'Devel::Cover';
};

