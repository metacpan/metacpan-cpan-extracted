use inc::Module::Install;

name q(Net-ISC-DHCPd);
all_from q(lib/Net/ISC/DHCPd.pm);
# requires Module::Install::ReadmeFromPod, comment out if you don't have it.
# This is mainly to keep the github README current.
readme_from q(lib/Net/ISC/DHCPd.pm);

requires q(File::Temp) => 0.20;
requires q(IO::Pty) => 1.00;
requires q(Moose) => 0.90;
requires q(MooseX::Types) => 0.12;
requires q(MooseX::Types::Path::Class) => 0.05;
requires q(NetAddr::IP) => 4.0;
requires q(Path::Class) => 0.19;
requires q(Time::HiRes) => 1.90;
requires q(Class::Load) => 0.20;
requires q(Class::Load) => 0.20;
requires q(Time::Local) => 1.18;

test_requires q(Benchmark) => 1.0;
test_requires q(Test::More) => 0.90;
test_requires q(Time::Local) => 1.18;

bugtracker q(https://github.com/jhthorsen/net-isc-dhcpd/issues);
homepage q(http://search.cpan.org/dist/Net-ISC-DHCPd);
repository q(git://github.com/jhthorsen/net-isc-dhcpd.git);

auto_install;
WriteAll;
