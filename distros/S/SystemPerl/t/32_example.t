#!/usr/bin/perl -w
# DESCRIPTION: Perl ExtUtils: Type 'make test' to test this package
#
# Copyright 2001-2014 by Wilson Snyder.  This program is free software;
# you can redistribute it and/or modify it under the terms of either the GNU
# Lesser General Public License Version 3 or the Perl Artistic License Version 2.0.

use strict;
use Test;

BEGIN { plan tests => 2 }
BEGIN { require "t/test_utils.pl"; }

use SystemC::Netlist;
ok(1);

{
    print "Checking example in Netlist.pm\n";
    my $nl = new SystemC::Netlist ();
    foreach my $file ('example/ExMod.sp', 'example/ExModSub.sp') {
	$nl->read_file (filename=>$file,
			strip_autos=>1);
    }
    $nl->link();
    $nl->autos();
    $nl->lint();
    $nl->exit_if_error();

    foreach my $mod ($nl->modules_sorted) {
	show_hier ($mod, "  ");
    }

    sub show_hier {
	my $mod = shift;
	my $indent = shift;
	print $indent,"Module ",$mod->name,"\n";
	foreach my $cell ($mod->cells_sorted) {
	    show_hier ($cell->submod, $indent."  ".$cell->name."  ");
	}
    }
}
ok(1);
