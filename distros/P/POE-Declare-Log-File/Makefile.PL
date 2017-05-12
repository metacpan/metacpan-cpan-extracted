use inc::Module::Install::DSL 1.01;

all_from      lib/POE/Declare/Log/File.pm
requires_from lib/POE/Declare/Log/File.pm
test_requires Test::More          0.47
test_requires Test::POE::Stopping 1.00
test_requires File::Remove        1.42
