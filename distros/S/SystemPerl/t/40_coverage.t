#!/usr/bin/perl -w
# DESCRIPTION: Perl ExtUtils: Type 'make test' to test this package
#
# Copyright 2001-2014 by Wilson Snyder.  This program is free software;
# you can redistribute it and/or modify it under the terms of either the GNU
# Lesser General Public License Version 3 or the Perl Artistic License Version 2.0.

use strict;
use Test;

BEGIN { plan tests => 12 }
BEGIN { require "t/test_utils.pl"; }

use SystemC::Coverage;
ok(1);

my $cov = new SystemC::Coverage;
ok($cov);

$cov->inc(comment=>'foo',filename=>__FILE__,lineno=>__LINE__,bar=>'bar',count=>10);
ok(1);

inc(type=>'block',comment=>'line',hier=>'a.b.c',filename=>__FILE__,lineno=>__LINE__,com2=>'testok',  count=>100);
inc(type=>'block',comment=>'line',hier=>'a.b.c',filename=>__FILE__,lineno=>__LINE__,com2=>'testlow', count=>1);
inc(type=>'block',comment=>'line',hier=>'a.b.c',filename=>__FILE__,lineno=>__LINE__,com2=>'testnone',count=>0);
ok(1);

my $icount=0;
foreach my $item ($cov->items_sorted) {
    print "  Filename ",$item->filename.":".$item->lineno," Count ",$item->count,"\n";
    $icount++;
}
ok($icount==4);

print "Non-binary:\n";

mkdir 'test_dir/logs', 0777;
$cov->write(filename=>'test_dir/logs/coverage.pl', binary=>0);
ok(1);

my $cov2 = new SystemC::Coverage;
$cov2->read(filename=>'test_dir/logs/coverage.pl');
ok ($cov2);

$cov2->write(filename=>'test_dir/logs/coverage2.pl', binary=>0);
ok (files_identical('test_dir/logs/coverage.pl', 'test_dir/logs/coverage2.pl'));

print "Binary:\n";

$cov->write(filename=>'test_dir/logs/coveragebin.dat', binary=>1);
ok(1);

my $cov3 = new SystemC::Coverage;
$cov3->read(filename=>'test_dir/logs/coveragebin.dat');
ok ($cov3);

$cov3->write(filename=>'test_dir/logs/coveragebin2.dat', binary=>1);
ok (files_identical('test_dir/logs/coveragebin.dat', 'test_dir/logs/coveragebin2.dat'));

##############################
print "Coverage program:\n";

run_system("cd test_dir ; ${PERL} ../vcoverage -y ../");
ok (-r "test_dir/logs/coverage_source/40_coverage.t");
