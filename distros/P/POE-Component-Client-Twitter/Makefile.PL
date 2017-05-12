use inc::Module::Install;
name 'POE-Component-Client-Twitter';
all_from 'lib/POE/Component/Client/Twitter.pm';

requires $_ for (qw/ HTTP::Request HTTP::Date JSON::Any POE POE::Component::Client::HTTP URI /);

build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
