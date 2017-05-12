use inc::Module::Install;

name     'POE-Component-Client-CouchDB';
all_from 'lib/POE/Component/Client/CouchDB.pm';
author   'Paul Driver <frodwith@cpan.org>';

build_requires 'Test::More';

requires 'Moose';
requires 'JSON';
requires 'POE';
requires 'POE::Component::Client::HTTP';

auto_install;

WriteAll;

