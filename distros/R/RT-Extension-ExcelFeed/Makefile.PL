use lib '.';
use inc::Module::Install;

RTx 'RT-Extension-ExcelFeed';
all_from 'lib/RT/Extension/ExcelFeed.pm';
readme_from 'lib/RT/Extension/ExcelFeed.pm';
license  'gplv2';

requires 'Excel::Writer::XLSX';
requires_rt '4.4.5';
rt_too_new '5.2.0';

sign;
WriteAll;
