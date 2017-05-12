use inc::Module::Install;

name     'Net-SNMP-QueryEngine-AnyEvent';
all_from 'lib/Net/SNMP/QueryEngine/AnyEvent.pm';
author   q{Anton Berezin <tobez@tobez.org>};
license  'bsd';

requires 'AnyEvent';
requires 'AnyEvent::Handle';
requires 'Data::MessagePack';
requires 'Data::MessagePack::Stream';
test_requires 'Test::More';

auto_install;

WriteAll;

