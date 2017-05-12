#!/usr/bin/perl -w

BEGIN
{
	chdir 't' if -d 't';
	use lib '../lib', '../blib/lib';
}

use strict;
use Test::More 'no_plan'; # tests => 1;

my $module = 'Module::Build::TestReporter';
use_ok( $module ) or exit;
