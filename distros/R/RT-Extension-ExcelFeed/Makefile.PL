use inc::Module::Install;

RTx 'RT-Extension-ExcelFeed';
all_from 'lib/RT/Extension/ExcelFeed.pm';
readme_from 'lib/RT/Extension/ExcelFeed.pm';
license  'gplv2';

requires 'Excel::Writer::XLSX';
requires_rt '4.2.0';
rt_too_new '4.6.0';

sign;
WriteAll;
