use inc::Module::Install;

name 'Plack-Server-AnyEvent-Server-Starter';

all_from 'lib/Plack/Server/AnyEvent/Server/Starter.pm';

requires 'AnyEvent';
requires 'AnyEvent::Socket';
requires 'AnyEvent::Util';
requires 'IO::Socket::INET';
requires 'Plack';
requires 'Plack::Server::AnyEvent';
requires 'Server::Starter';

test_requires 'LWP';
test_requires 'Test::More';
test_requires 'Test::TCP';

WriteAll;