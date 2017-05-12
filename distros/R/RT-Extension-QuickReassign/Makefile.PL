use inc::Module::Install;


RTx 'RT-Extension-QuickReassign';
all_from 'lib/RT/Extension/QuickReassign.pm';
readme_from 'lib/RT/Extension/QuickReassign.pm';
license  'gplv2';

requires_rt('3.8.4'); # may work with older versions, but 3.8.4 and up is known good

sign;
WriteAll;
