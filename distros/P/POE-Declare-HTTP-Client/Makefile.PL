use inc::Module::Install::DSL 1.00;

all_from      lib/POE/Declare/HTTP/Client.pm
requires_from lib/POE/Declare/HTTP/Client.pm
test_requires Test::More          0.42
test_requires Test::NoWarnings    1.00
test_requires Test::POE::Stopping 1.07
