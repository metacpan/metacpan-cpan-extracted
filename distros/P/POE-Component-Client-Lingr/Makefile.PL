use inc::Module::Install;
name 'POE-Component-Client-Lingr';
all_from 'lib/POE/Component/Client/Lingr.pm';

requires 'POE';
requires 'POE::Component::Client::HTTP';
requires 'Data::Visitor::Callback';
requires 'JSON::Syck';
requires 'HTTP::Request';
requires 'URI';

build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
