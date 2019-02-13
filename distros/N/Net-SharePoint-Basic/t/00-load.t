#!perl

use 5.10.1;
use strict;
use warnings;
use Test::More;

# Copyright 2018 VMware, Inc.
# SPDX-License-Identifier: Artistic-1.0-Perl

plan tests => 1;

BEGIN {
    use_ok( 'Net::SharePoint::Basic' ) || print "Bail out!\n";
}

diag( "Testing Net::SharePoint::Basic $Net::SharePoint::Basic::VERSION, Perl $], $^X" );
