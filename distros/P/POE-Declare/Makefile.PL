use inc::Module::Install::DSL 1.04;

all_from      lib/POE/Declare.pm
requires_from lib/POE/Declare.pm
requires_from lib/POE/Declare/Meta.pm
test_requires Test::More          0.80
test_requires Test::Exception     0.27
test_requires Test::NoWarnings    0.084
test_requires Test::POE::Stopping 1.09
