use strict;
use warnings;

use inc::Module::Install;

name 'Net-Magrathea';
all_from 'lib/Net/Magrathea.pm';

requires 'Moose'       => '0.93';
requires 'Net::Telnet' => '3.03';
requires 'namespace::autoclean' => '0.09';

test_requires 'Test::More'         => '0.47';

auto_install;

WriteAll;
