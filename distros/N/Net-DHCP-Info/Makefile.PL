use inc::Module::Install;

name     q(Net-DHCP-Info);
all_from q(lib/Net/DHCP/Info.pm);

requires      q(DateTime)           => 0;
requires      q(NetAddr::IP)        => 0;
test_requires q(Test::More)         => 0;
test_requires q(Test::Perl::Critic) => 0;
test_requires q(Test::Pod)          => 0;

auto_install;
WriteAll;
