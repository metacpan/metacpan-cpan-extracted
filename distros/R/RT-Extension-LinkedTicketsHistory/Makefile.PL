use inc::Module::Install;


RTx 'RT-Extension-LinkedTicketsHistory';
all_from 'lib/RT/Extension/LinkedTicketsHistory.pm';
readme_from 'lib/RT/Extension/LinkedTicketsHistory.pm';
license  'gplv2';

sign;
WriteAll;
