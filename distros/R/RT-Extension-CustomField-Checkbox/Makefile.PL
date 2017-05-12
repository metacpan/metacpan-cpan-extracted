use inc::Module::Install;
RTx('RT-Extension-CustomField-Checkbox');
rt_too_new('4.0.0',"You don't need this extension.\nRT 4.0 and newer has this functionality built in.\n");
all_from('lib/RT/Extension/CustomField/Checkbox.pm');
readme_from();
WriteAll();
