use lib '.';
use inc::Module::Install;
RTx('RT-Extension-ExtractCustomFieldValues');

repository('https://github.com/bestpractical/rt-extension-extractcustomfieldvalues');

requires_rt('4.0.0');
rt_too_new('6.2.0');

sign;
&WriteAll;
