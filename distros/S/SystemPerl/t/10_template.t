#!/usr/bin/perl -w
# DESCRIPTION: Perl ExtUtils: Type 'make test' to test this package
#
# Copyright 2001-2014 by Wilson Snyder.  This program is free software;
# you can redistribute it and/or modify it under the terms of either the GNU
# Lesser General Public License Version 3 or the Perl Artistic License Version 2.0.

use strict;
use Test;

BEGIN { plan tests => 9 }
BEGIN { require "t/test_utils.pl"; }

use SystemC::Template;
use SystemC::Netlist;
ok(1);

# Better written as, but not backward compatible:
#my $tpl = new SystemC::Template (logger=>Verilog::Netlist::Logger->new());
my $tpl = new SystemC::Template (logger=>SystemC::Netlist::new_logger());
ok($tpl);

$tpl->read (filename=>'t/10_template.in',);
ok(1);

$tpl->print ("inserted: This is line 1\n");
ok(1);

$tpl->printf ("inserted: This is line %d\n", 2);
ok(1);

$tpl->print_ln ("newfilename", 100, "inserted: This is line 100 of newfile\n");
ok(1);

foreach my $lref (@{$tpl->src_text()}) {
    #print "GOT LINE $lref->[1], $lref->[2], $lref->[3]";
    $tpl->print_ln ($lref->[1], $lref->[2], $lref->[3]);
}

$tpl->printf ("inserted: This is the bottom of the file\n");
ok(1);

$tpl->write( filename=>'test_dir/10_template.out',
	     ppline=>1,
	     );
ok(1);

ok (files_identical ('test_dir/10_template.out', 't/10_template.out'));
