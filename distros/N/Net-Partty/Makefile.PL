use inc::Module::Install;
name 'Net-Partty';
all_from 'lib/Net/Partty.pm';

requires $_ for (qw/
    Carp
    Class::Accessor::Fast
    IO::Select
    IO::Socket::Telnet
/);

build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
