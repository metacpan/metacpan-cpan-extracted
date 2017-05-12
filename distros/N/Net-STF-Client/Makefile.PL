use strict;
use inc::Module::Install;

name 'Net-STF-Client';

all_from 'lib/Net/STF/Client.pm';

requires 'Class::Accessor::Lite';
requires 'Furl';
requires 'HTTP::Status';
requires 'MIME::Base64';
requires 'Scalar::Util';
requires 'URI';
test_requires 'Test::More';
test_requires 'Test::Requires';

WriteAll;