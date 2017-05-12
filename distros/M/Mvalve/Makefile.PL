use strict;
use inc::Module::Install;

name('Mvalve');
all_from('lib/Mvalve.pm');

requires('Cache::Memcached');
requires('Config::Any');
requires('Data::Serializer');
requires('Data::Valve', '0.00007');
requires('DBI');
requires('Digest::SHA1');
requires('Exporter', '5.61');
requires('HTTP::Headers');
requires('Moose');
requires('MooseX::App::Cmd', '0.03');
requires('MooseX::ClassAttribute');
requires('MooseX::ConfigFromFile');
requires('MooseX::KeyedMutex');
requires('MooseX::Q4MLog');
requires('Queue::Q4M', '0.00009');
requires('Sys::Hostname');
requires('Time::HiRes');
requires('UNIVERSAL::require');

test_requires('Test::More');
test_requires('Test::UseAllModules');

install_script('script/mvalve');

auto_include;
WriteAll;
