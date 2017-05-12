use inc::Module::Install;


RTx 'RT-Extension-TrailingSubjectTag';
all_from 'lib/RT/Extension/TrailingSubjectTag.pm';
readme_from 'lib/RT/Extension/TrailingSubjectTag.pm';
license  'gplv2';

sign;
WriteAll;
