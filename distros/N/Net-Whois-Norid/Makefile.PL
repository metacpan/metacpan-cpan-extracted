use strict;
use inc::Module::Install;

name 'Net-Whois-Norid';

all_from 'lib/Net/Whois/Norid.pm';

# lib/
requires 'Net::Whois::Raw' => 0;

# t/
build_requires 'Test::More' => 0;

auto_install;
WriteAll;


