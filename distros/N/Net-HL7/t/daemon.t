# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

BEGIN {
	$| = 1; 
	print "1..3\n";

	unshift(@INC, "./lib");
}

END {
	print "not ok 1\n" unless $loaded;
}

$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# util
sub testEq {
    local($^W) = 0;
    my($num, $was, $expected) = @_;
    print(($expected eq $was) ? "ok $num\n" : "not ok $num: Expected $expected, was $was\n");
}

sub testNe {
    local($^W) = 0;
    my($num, $was, $expected) = @_;
    print(($expected ne $was) ? "ok $num\n" : "not ok $num: Expected $expected, was $was\n");
}

require 5.004_05;
use Config; my $perl = $Config{'perlpath'};
use Net::HL7::Daemon;

my $d = new Net::HL7::Daemon(LocalPort => 12009);

testNe(2, $d->getHost(), "");
testEq(3, $d->getPort(), "12009");

$d->close();
