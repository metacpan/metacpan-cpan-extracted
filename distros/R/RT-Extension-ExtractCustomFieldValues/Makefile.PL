use inc::Module::Install;
RTx('RT-Extension-ExtractCustomFieldValues');

repository('https://github.com/bestpractical/rt-extension-extractcustomfieldvalues');

requires_rt('4.0.0');
rt_too_new('4.6.0');

sign;
&WriteAll;
