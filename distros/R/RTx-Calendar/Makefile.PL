use lib '.';
use inc::Module::Install;

RTx('RTx-Calendar');

requires 'DateTime';
requires 'DateTime::Set';

requires_rt '4.2.0';

sign();
WriteAll();
