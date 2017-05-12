#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 7;

######
# Test SOAP::XML::Client
######

BEGIN { use_ok( 'SOAP::XML::Client' ); }

########
# Test SOAP::XML::Client::Generic
########

BEGIN { use_ok( 'SOAP::XML::Client::Generic' ); }

# I need to set up a Real soap server so I can run tests
# against it.

# Check that we croak in the right places
my @methods = qw(uri xmlns proxy);
my %conf;
foreach my $method (@methods) {
	eval {
		SOAP::XML::Client->new(\%conf);
	};
	like($@,qr/$method is requ/,"new() - $method check works");
	$conf{$method} = 'value';
}

# Now we should have everything - so we shouldn't croak
my $obj;
eval {
	$obj = SOAP::XML::Client::Generic->new(\%conf);
};
is($@,'','new() - created object ok');

unless(my $foo = $obj->fetch({ method => 'test', 'xml' => '<invalid xml>'})) {
	like($obj->error(), qr/Error parsing your XML/,'fetch() - graceful croak on dodgy XML');
}


