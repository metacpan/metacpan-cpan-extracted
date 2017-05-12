use inc::Module::Install;
name 'POE-Component-Client-HTTPDeferred';
all_from 'lib/POE/Component/Client/HTTPDeferred.pm';

requires 'POE';
requires 'POE::Component::Client::HTTP';
requires 'Any::Moose';

test_requires 'Test::More';
test_requires 'HTTP::Request::Common';

use_test_base;
auto_include;
WriteAll;
