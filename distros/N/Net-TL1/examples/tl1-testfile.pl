#!/usr/bin/perl -w

# This example uses the new testing functionality in version 0.05. It 
# reads the test file for the ASAM 7301, parses the output and dumps
# the contents of the data structure to STDOUT

use strict;

use Net::TL1;

my $debug = 0;

{
	my $tl1 = new Net::TL1({Debug => 0});

	my $testref = $tl1->read_testfile('../t/asam7301-test.data');

	my $cmd = 'REPT-OPSTAT-XBEARER:PR-DSLAM1:XDSL-1-1-2-1:111:;';
	$tl1->Execute($cmd, @{$$testref{$cmd}{output}});
	$tl1->ParseSimpleOutputLines(111);
	my $ref = $tl1->get_hashref;


use Data::Dumper;
	print Dumper($ref);

}

