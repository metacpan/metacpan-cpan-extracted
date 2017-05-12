use inc::Module::Install;

name q(POE-Filter-DHCPd-Lease);
all_from q(lib/POE/Filter/DHCPd/Lease.pm);

requires q(POE::Filter) => 1.2;
requires q(Time::Local) => 1.1;

test_requires q(Test::More) => 0.9;

bugtracker q(https://github.com/jhthorsen/poe-filter-dhcpd-lease/issues);
homepage q(http://search.cpan.org/dist/POE-Filter-DHCPd-Lease);
repository q(git://github.com/jhthorsen/poe-filter-dhcpd-lease.git);

auto_install;
WriteAll;
