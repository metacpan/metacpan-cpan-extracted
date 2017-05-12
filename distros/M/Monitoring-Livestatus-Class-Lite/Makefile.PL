use inc::Module::Install;

name     'Monitoring-Livestatus-Class-Lite';
all_from 'lib/Monitoring/Livestatus/Class/Lite.pm';
author   q{Sven Nierlein <nierlein@cpan.org>};
license  'perl';
repository 'http://github.com/sni/Monitoring-Livestatus-Class-Lite';

requires 'Monitoring::Livestatus' => '0.54';

build_requires 'Test::More';

auto_install;

WriteAll;
