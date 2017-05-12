use inc::Module::Install;

name     'Monitoring-Livestatus-Class';
all_from 'lib/Monitoring/Livestatus/Class.pm';
author   q{Robert Bohne <rbo@cpan.org>};
license  'perl';
repository 'http://github.com/rbo/Monitoring-Livestatus-Class';

requires 'Moose';
requires 'Module::Find';
requires 'Class::Load';
requires 'Monitoring::Livestatus' => '0.54';

build_requires 'Test::More';

auto_install;

WriteAll;
