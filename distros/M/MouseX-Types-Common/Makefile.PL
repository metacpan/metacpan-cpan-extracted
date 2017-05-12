#!/usr/bin/perl -w
use strict;
use inc::Module::Install;

name     'MouseX-Types-Common';
license  'perl';
all_from 'lib/MouseX/Types/Common.pm';

# prereqs
requires 'Mouse'          => '0.42';
requires 'MouseX::Types'  => '0.01';

# things the tests need
test_requires 'Test::More' => '0.62';

WriteAll;
