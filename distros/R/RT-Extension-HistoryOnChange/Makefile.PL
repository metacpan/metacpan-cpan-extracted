use inc::Module::Install;


RTx 'RT-Extension-HistoryOnChange';
all_from 'lib/RT/Extension/HistoryOnChange.pm';
readme_from 'lib/RT/Extension/HistoryOnChange.pm';
license  'gplv2';
requires_rt('4.2.0');

WriteAll;
