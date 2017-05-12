#!/usr/bin/perl
use strict;
use warnings;
use Dir::Self;
BEGIN {
	require (__DIR__ . "/common.pm");
}

use Ref::Store::XS;
$HRTests::Impl = 'Ref::Store::XS';
HRTests::test_all();
