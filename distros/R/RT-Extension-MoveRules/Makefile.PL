use inc::Module::Install;

RTx('RT-Extension-MoveRules');
all_from 'lib/RT/Extension/MoveRules.pm';
readme_from 'lib/RT/Extension/MoveRules.pm';

WriteAll;
