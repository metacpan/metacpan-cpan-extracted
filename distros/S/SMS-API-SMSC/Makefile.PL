use inc::Module::Install;

name 'SMS-API-SMSC';
all_from 'lib/SMS/API/SMSC.pm';

requires 'LWP::UserAgent';
requires 'URI::Escape';

WriteAll;
