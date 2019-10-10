#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

my $extra_tests=0;

BEGIN {
    use_ok( 'Net::CIDR::Overlap' ) || print "Bail out!\n";
}

my $nco;
my $worked=0;
eval{
	$nco=Net::CIDR::Overlap->new;
	$worked=1;
};
ok( $worked eq '1', 'init') or diag("Net::CIDR::Overlap->new died with ".$@);

$worked=0;
eval{
	$nco->add('a');
	$worked=1;
};
ok( $worked eq '0', 'bad CIDR 1') or diag("'a' was accepted as a CIDR");

$worked=0;
eval{
	$nco->add('127.0.0.1/24');
	$worked=1;
};
ok( $worked eq '0', 'bad CIDR 2') or diag("'127.0.0.1/24' was accepted as a CIDR");

$worked=0;
eval{
	$nco->add('127.0.0.0/24');
	$worked=1;
};
ok( $worked eq '1', 'good CIDR') or diag("'127.0.0.0/24' was not accepted as a CIDR... $@=".$@);

done_testing(5);
