use inc::Module::Install;
use lib 'lib';
use 5.005;

name 'Monitoring-Generator-TestConfig';
all_from 'lib/Monitoring/Generator/TestConfig.pm';

license 'gpl3';
resources(
    'homepage',   => 'https://github.com/sni/Monitoring-Generator-TestConfig',
    'bugtracker'  => 'https://github.com/sni/Monitoring-Generator-TestConfig/issues',
    'repository', => 'https://github.com/sni/Monitoring-Generator-TestConfig',
);

requires 'Getopt::Long';
requires 'Pod::Usage';
requires 'Sys::Hostname';
requires 'Getopt::Long';
requires 'Time::HiRes';
requires 'Carp';
requires 'POSIX';
requires 'Data::Dumper';
requires 'IPC::Cmd';

test_requires 'Test::More'    => 0.87;
test_requires 'File::Temp';
test_requires 'File::Basename';

install_script 'bin/create_monitoring_test_config.pl';

auto_install;
WriteAll;
