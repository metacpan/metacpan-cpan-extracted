use inc::Module::Install;

RTx 'RT-Extension-EscalationDates';

all_from 'lib/RT/Extension/EscalationDates.pm';
license 'perl';
readme_from;
repository 'git://git.benjaminheisig.net/rt-extension-escalationdates.git';

requires_rt('4.0.0');
requires 'Date::Manip' => '6.25';
auto_install();

sign;
&WriteAll;
