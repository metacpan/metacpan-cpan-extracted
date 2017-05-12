#!perl -T

use warnings;
use strict;
use Test::Config::System tests => 2;

check_file_contents('lib/Test/Config/System.pm', qr/^package Test::Config::System;/, 'check_file_contents(pass)');
check_file_contents('/bogus/file/-/aoeu', qr//, 'check_file_contents(fail,inverted)', 1);
