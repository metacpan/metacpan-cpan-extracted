use warnings;
use strict;
use inc::Module::Install;

name     'Net-Trac';
all_from 'lib/Net/Trac.pm';
license  'perl';

requires 'Any::Moose';
requires 'URI';
requires 'LWP::Simple';
requires 'Params::Validate';
requires 'WWW::Mechanize' => '1.52';
requires 'DateTime';
requires 'HTTP::Date';
requires 'Lingua::EN::Inflect';
requires 'URI::Escape';
requires 'Text::CSV';

auto_install;
sign; 
WriteAll;

