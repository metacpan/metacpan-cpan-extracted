#!/usr/bin/perl -w

use strict;
use blib;

use Test::More tests => 7;

######
# Test SOAP::Lite::Simple
######

BEGIN { use_ok( 'SOAP::Lite::Simple' ); }

########
# Test SOAP::Lite::Simple::Real
########

BEGIN { use_ok( 'SOAP::Lite::Simple::Real' ); }

# I need to set up a Real soap server so I can run tests
# against it.

# Check that we croak in the right places
my @methods = qw(uri xmlns proxy);
my %conf;
foreach my $method (@methods) {
	eval {
		SOAP::Lite::Simple->new(\%conf);
	};
	like($@,qr/$method is requ/,"new() - $method check works");
	$conf{$method} = 'value';
}

# Now we should have everything - so we shouldn't croak
my $obj;
eval {
	$obj = SOAP::Lite::Simple::Real->new(\%conf);
};
is($@,'','new() - created object ok');

unless(my $foo = $obj->fetch({ method => 'test', 'xml' => '<invalid xml>'})) {
	like($obj->error(), qr/Error parsing your XML/,'fetch() - graceful croak on dodgy XML');
}


