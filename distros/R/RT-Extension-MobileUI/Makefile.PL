use inc::Module::Install;

RTx('RT-Extension-MobileUI');
all_from('lib/RT/Extension/MobileUI.pm');
readme_from('lib/RT/Extension/MobileUI.pm');

rt_too_new('4.0.0');

&WriteAll;
