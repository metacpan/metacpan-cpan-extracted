use inc::Module::Install;

RTx 'RT-Condition-NotStartedInBusinessHours';

all_from 'lib/RT/Condition/NotStartedInBusinessHours.pm';
license 'perl';
readme_from;
repository 'https://github.com/bheisig/rt-condition-notstartedinbusinesshours.git';

requires 'Date::Manip' => '6.34';
auto_install();

sign;
&WriteAll;
