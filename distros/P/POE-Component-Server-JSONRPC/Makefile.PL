use inc::Module::Install;
name 'POE-Component-Server-JSONRPC';
all_from 'lib/POE/Component/Server/JSONRPC.pm';

build_requires 'Test::More';

requires 'Class::Accessor::Fast';
requires 'POE';
requires 'POE::Filter::Line';
requires 'POE::Component::Server::SimpleHTTP';
requires 'POE::Component::Server::TCP';
requires 'JSON';
requires 'JSON::Client::RPC';

use_test_base;
auto_include;
WriteAll;
