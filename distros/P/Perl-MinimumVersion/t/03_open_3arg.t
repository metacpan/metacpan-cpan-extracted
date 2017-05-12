#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More 0.47;

#use version;
use Perl::MinimumVersion;
my @examples_not3arg = (
	q{close $x;},
	q{open A,'test.txt'},
	q{open INFO,   "<  datafile"  or print "can't open datafile: ",$!;},
	q{open INFO,   "<  datafile"  or die;},
	q{open(INFO,      "datafile") || die("can't open datafile: $!");},
	q{open my $fh, ">$output";},
	q/if(open my $fh, $output) {}/,
);
my @examples_3arg = (
	q{open A,'<','test.txt';},
	q{open( INFO, ">", $datafile ) || die "Can't create $datafile: $!";},
	q{open( INFO, ">", $datafile )},
	q{open my $fh, '>', $output;},
	q/if(open my $fh, '>', $output) {}/,
	q{open my $fh, '|-', 'test','arg1';},
);
plan tests =>(@examples_3arg+@examples_not3arg);
foreach my $example (@examples_not3arg) {
	my $p = Perl::MinimumVersion->new(\$example);
	is( $p->_three_argument_open, '', $example );
}
foreach my $example (@examples_3arg) {
	my $p = Perl::MinimumVersion->new(\$example);
	ok( $p->_three_argument_open, $example );
}
