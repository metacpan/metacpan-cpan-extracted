use inc::Module::Install;


RTx 'RTx-QuickUpdateUserComments';
all_from 'lib/RTx/QuickUpdateUserComments.pm';
readme_from 'lib/RTx/QuickUpdateUserComments.pm';
license  'gplv2';

requires_rt('4.2.0');

sign;
WriteAll;
