use inc::Module::Install;

RTx     'RT-Condition-UntouchedInBusinessHours';
author   'Kevin Falcone <falcone@bestpractical.com>';
all_from 'lib/RT/Condition/UntouchedInBusinessHours.pm';
readme_from 'lib/RT/Condition/UntouchedInBusinessHours.pm';

build_requires 'Test::More';

requires 'Business::Hours';

auto_install;

WriteAll;

