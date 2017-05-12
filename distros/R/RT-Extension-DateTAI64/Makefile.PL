use inc::Module::Install;


RTx 'RT-Extension-DateTAI64';
all_from 'lib/RT/Extension/DateTAI64.pm';
readme_from 'lib/RT/Extension/DateTAI64.pm';
license  'gplv2';

requires('Time::TAI64');

sign;
WriteAll;
