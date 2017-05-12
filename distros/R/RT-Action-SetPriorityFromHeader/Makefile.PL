use inc::Module::Install;


RTx 'RT-Action-SetPriorityFromHeader';
all_from 'lib/RT/Action/SetPriorityFromHeader.pm';
readme_from 'lib/RT/Action/SetPriorityFromHeader.pm';
license  'gplv2';

requires_rt('3.8.0');

sign;
WriteAll;
