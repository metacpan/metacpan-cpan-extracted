use inc::Module::Install;
name 'Sledge-SessionManager-MobileID';
all_from 'lib/Sledge/SessionManager/MobileID.pm';

requires $_ for (qw/Digest::SHA1 Time::HiRes/);

build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
