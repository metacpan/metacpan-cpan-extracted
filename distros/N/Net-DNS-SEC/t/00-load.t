#!/usr/bin/perl
# $Id: 00-load.t 1831 2021-02-11 23:03:17Z willem $	-*-perl-*-
#

use strict;
use warnings;
use Test::More tests => 4;

my @module = qw(
		Net::DNS::SEC
		Net::DNS::SEC::DSA
		Net::DNS::SEC::ECDSA
		Net::DNS::SEC::ECCGOST
		Net::DNS::SEC::EdDSA
		Net::DNS::SEC::RSA
		Net::DNS::SEC::Digest
		Net::DNS::SEC::Keyset
		Net::DNS::SEC::Private
		Net::DNS::SEC::libcrypto
		File::Spec
		IO::File
		MIME::Base64
		Net::DNS
		Test::More
		);


my @diag = "\nThese tests were run using:";
foreach my $module ( sort @module ) {
	eval "require $module";		## no critic
	for ( eval { $module->VERSION || () } ) {
		s/^(\d+\.\d)$/${1}0/;
		push @diag, sprintf "%-25s  %s", $module, $_;
	}
}
diag join "\n\t", @diag;


ok( eval { Net::DNS::SEC::libcrypto->VERSION }, 'XS component SEC.xs loaded' )
		|| BAIL_OUT("Unable to access OpenSSL libcrypto library");

use_ok('Net::DNS::SEC');


my @index;
foreach my $class ( map {"Net::DNS::SEC::$_"} qw(RSA DSA ECCGOST ECDSA EdDSA) ) {
	my @algorithms = eval join '', qw(r e q u i r e), " $class; $class->_index";	## no critic
	push @index, map { $_ => $class } @algorithms;
}
ok( scalar(@index), 'create consolidated algorithm index' );


eval {
	# Exercise checkerr() response to failed OpenSSL operation
	Net::DNS::SEC::libcrypto::checkerr(0);
};
my ($exception) = split /\n/, "$@\n";
ok( $exception, "XS libcrypto error\t[$exception]" );


eval {
	# Exercise residual XS support for deprecated ECCGOST algorithm
	my $d = pack 'H*', '9df69fc32cd2d369a42ecb63512bc7e25d71b1af7a303ec38a8326809cdef349';
	my $q = pack 'H*', 'ffffffffffffffffffffffffffffffff6c611070995ad10045841b09b761b893';
	my $r = pack 'H*', '36b98722d79b1cce42cdb9a6503d2fa16ce85969eae711b758aabfe3a39f5d0c';
	my $s = pack 'H*', '22c1d462f790afab1624e211531d1d455d285978bb0d4875c428811d7028fc33';
	my $x = pack 'H*', 'cadb74b9950fcf3728ad232626b0dc63f350c25dd09456cd155f413d35205ce9';
	my $y = pack 'H*', '050fd637ab18f8f443eac48c26c12566e655e4d3b15046e0fef296a8835ebeee';
	foreach my $H ( $d, $q ) {	## including specific case  (alpha mod q) = 0
		my $eckey = Net::DNS::SEC::libcrypto::EC_KEY_new_ECCGOST( $x, $y );
		Net::DNS::SEC::libcrypto::ECCGOST_verify( $H, $r, $s, $eckey );
	}
};

exit;


END {
	eval { Net::DNS::SEC::libcrypto::croak_memory_wrap() }	# paper over crack in Devel::Cover
}


__END__

