use inc::Module::Install;

name           'Tail-Stat';
all_from       'lib/Tail/Stat.pm';
license        'perl';

requires       'DateTime';
requires       'JSON::XS';
requires       'Log::Dispatch' => 2.26;
requires       'POE';
requires       'Pid::File::Flock';
requires       'Sys::Syslog' => 0.16;
requires       'Tie::Hash::Indexed';

test_requires  'Test::More';
test_requires  'Test::TCP';

install_script 'bin/tstatd';

auto_install;

WriteAll;

