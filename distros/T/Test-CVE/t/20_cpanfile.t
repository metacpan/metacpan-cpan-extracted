#!/usr/bin/perl

use 5.014000;
use warnings;

use Test::More;
use Test::CVE;

my $test = Test::CVE->new (
    verbose  => 0,
    deps     => 1,
    minimum  => 0,
    cpanfile => "files/cpanfile-SR",
    );

isa_ok ($test, "Test::CVE",  "Object created");

# Internal, undocumented, test only
$test->_read_cpanfile ();
    
is_deeply ($test->{prereq}{"ExtUtils-MakeMaker"}, {
    recommends       => "7.22",
    requires         => undef,
    v                => {
	""               => "requires",
	"7.22"           => "recommends",
	},
    }, "Versions for ExtUtils::MakeMaker");

done_testing;
