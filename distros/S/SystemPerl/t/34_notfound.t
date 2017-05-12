#!/usr/bin/perl -w
# DESCRIPTION: Perl ExtUtils: Type 'make test' to test this package
#
# Copyright 2001-2014 by Wilson Snyder.  This program is free software;
# you can redistribute it and/or modify it under the terms of either the GNU
# Lesser General Public License Version 3 or the Perl Artistic License Version 2.0.

use strict;
use Test;

BEGIN { plan tests => 4 }
BEGIN { require "t/test_utils.pl"; }

use SystemC::Netlist;
ok(1);

{
    my $nl = new SystemC::Netlist (link_read_nonfatal=>1,);
    ok($nl);

    $nl->read_file (filename=>"t/34_notfound.sp");
    ok($nl);

    $nl->link();
    ok($nl);
}
