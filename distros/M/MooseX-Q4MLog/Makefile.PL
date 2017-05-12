use strict;
use inc::Module::Install;

name('MooseX-Q4MLog');

all_from('lib/MooseX/Q4MLog.pm');
requires('Moose');
requires('MooseX::ConfigFromFile');
requires('MooseX::Daemonize');
requires('Queue::Q4M');

auto_include;
WriteAll;