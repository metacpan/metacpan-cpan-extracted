use inc::Module::Install;

RTx 'RT-Extension-MandatoryFields';

all_from 'lib/RT/Extension/MandatoryFields.pm';
license 'perl';
readme_from;
repository 'git://git.benjaminheisig.net/rt-extension-mandatoryfields.git';

requires_rt('4.0.0');
auto_install();

sign;
&WriteAll;
