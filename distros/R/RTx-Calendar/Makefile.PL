use inc::Module::Install;

RTx('RTx-Calendar');

requires 'DateTime';
requires 'DateTime::Set';

requires_rt '4.0.9';

sign();
WriteAll();
