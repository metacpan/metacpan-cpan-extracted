use inc::Module::Install;


RTx 'RT-Extension-NotifyBasedOnOwnership';
all_from 'lib/RT/Extension/NotifyBasedOnOwnership.pm';
readme_from 'lib/RT/Extension/NotifyBasedOnOwnership.pm';
license  'gplv2';

requires_rt('4.0.0');

sign;
WriteAll;
