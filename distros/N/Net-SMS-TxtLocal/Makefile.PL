use strict;
use warnings;
use inc::Module::Install;

name 'Net-SMS-TxtLocal';
all_from 'lib/Net/SMS/TxtLocal.pm';

requires 'Carp';
requires 'JSON' => '2.16';
requires 'LWP::UserAgent';
requires 'Moose';
requires 'namespace::autoclean';

test_requires 'Test::More';
test_requires 'Test::Exception';

WriteAll();
