use inc::Module::Install;

RTx('RT-Extension-CSAT');
all_from('lib/RT/Extension/CSAT.pm');

license('perl');
requires_rt('5.0.0');

WriteAll;
