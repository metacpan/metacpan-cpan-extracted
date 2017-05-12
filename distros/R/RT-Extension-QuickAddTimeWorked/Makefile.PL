use inc::Module::Install;


RTx 'RT-Extension-QuickAddTimeWorked';
all_from 'lib/RT/Extension/QuickAddTimeWorked.pm';
readme_from 'lib/RT/Extension/QuickAddTimeWorked.pm';
license  'gplv2';

requires_rt("3.8.3");

sign;
WriteAll;
