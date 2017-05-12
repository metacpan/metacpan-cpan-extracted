use inc::Module::Install;

RTx('RT-Extension-SkipQuotes');
all_from('lib/RT/Extension/SkipQuotes.pm');
readme_from('lib/RT/Extension/SkipQuotes.pm');

WriteAll();
