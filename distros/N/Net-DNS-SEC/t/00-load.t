# $Id: 00-load.t 1494 2016-08-22 09:34:07Z willem $
# 

use strict;
use Test::More tests => 1;


my @module = qw(
	Net::DNS::SEC
	Net::DNS::SEC::DSA
	Net::DNS::SEC::ECCGOST
	Net::DNS::SEC::ECDSA
	Net::DNS::SEC::RSA
	Net::DNS::SEC::Keyset
	Net::DNS::SEC::Private
	Crypt::OpenSSL::Bignum
	Crypt::OpenSSL::Random
	Crypt::OpenSSL::DSA
	Crypt::OpenSSL::EC
	Crypt::OpenSSL::ECDSA
	Crypt::OpenSSL::RSA
	Digest::GOST
	Digest::SHA
	File::Spec
	MIME::Base64
	Net::DNS
	);


diag("\nThese tests were run with:\n");
foreach my $module (@module) {
	my $loaded = eval("require $module") || 0;
	my $revnum = $loaded ? $module->VERSION : "\t\tn/a";
	diag sprintf "\t%-25s  %s", $module, $revnum || '?';
}


use_ok('Net::DNS::SEC');

