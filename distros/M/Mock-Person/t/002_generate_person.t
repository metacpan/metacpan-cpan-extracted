#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use Test::More tests => 6;

BEGIN { use_ok 'Mock::Person' }
like(Mock::Person::name( country=> 'ru', sex=> 'male'), qr/\w+\s\w+\s\w+/, 'name sould match regexp');
like(Mock::Person::name( country=> 'ru', sex=> 'female'), qr/\w+\s\w+\s\w+/, 'name sould match regexp');
like(Mock::Person::name( sex=> 'male'), qr/\w+\s\w+\s\w+/, 'name sould match regexp');
like(Mock::Person::name( sex=> 'female'), qr/\w+\s\w+\s\w+/, 'name sould match regexp');
like(Mock::Person::name(), qr/\w+\s\w+\s\w+/, 'name sould match regexp');
