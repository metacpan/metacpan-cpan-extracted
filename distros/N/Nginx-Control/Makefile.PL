use strict;
use warnings;
use inc::Module::Install;

die "This module is not for use on Windows, sorry."
    if  $^O eq 'Win32' or $^O eq 'cygwin';

name 'Nginx-Control';
all_from 'lib/Nginx/Control.pm';
license 'perl';

# prereqs
requires 'Moose' => 0.32;
requires 'MooseX::Types::Path::Class';

# things the tests need
test_requires 'Test::More';
test_requires 'Test::Exception';
test_requires 'Test::WWW::Mechanize';
test_requires 'Test::TempDir';

tests('t/*.t');

WriteAll();

