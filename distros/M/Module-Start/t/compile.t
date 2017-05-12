use Test::More tests => 5;

is eval("use Module::Start; 1"), 1,
    'Module::Start compiles';
    print $@;
is eval("use Module::Start::Config; 1"), 1,
    'Module::Start::Config compiles';
is eval("use Module::Start::Base; 1"), 1,
    'Module::Start::Base compiles';
is eval("use Module::Start::Flavor; 1"), 1,
    'Module::Start::Flavor compiles';
is eval("use Module::Start::Flavor::Basic; 1"), 1,
    'Module::Start::Flavor::Basic compiles';
