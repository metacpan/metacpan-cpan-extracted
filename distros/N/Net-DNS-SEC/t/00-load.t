# $Id: 00-load.t 1705 2018-08-23 10:24:02Z willem $
#

use strict;
use Test::More tests => 3;

my @module = qw(
	Net::DNS::SEC
	Net::DNS::SEC::DSA
	Net::DNS::SEC::ECDSA
	Net::DNS::SEC::ECCGOST
	Net::DNS::SEC::EdDSA
	Net::DNS::SEC::RSA
	Net::DNS::SEC::Keyset
	Net::DNS::SEC::Private
	Net::DNS::SEC::libcrypto
	Digest::GOST
	File::Find
	File::Spec
	IO::File
	MIME::Base64
	Net::DNS
	Test::More
	);


my @diag = "\nThese tests were run using:";
foreach my $module ( sort @module ) {
	eval "require $module";
	my $version = eval { $module->VERSION } || next;
	$version =~ s/(\.\d)$/${1}0/;
	push @diag, sprintf "%-25s  %s", $module, $version;
}
diag join "\n\t", @diag;


ok( eval { Net::DNS::SEC::libcrypto->VERSION }, 'XS component SEC.xs loaded' )
		|| BAIL_OUT "Unable to access OpenSSL libcrypto library";

use_ok('Net::DNS::SEC');

eval {
	my $evpkey = Net::DNS::SEC::libcrypto::EVP_PKEY_new();
	my $broken = Net::DNS::SEC::libcrypto::EVP_sign( 'sigdata', $evpkey );
};
my $exception = $1 if $@ =~ /^(.+)\n/;
ok( $exception ||= '', "XS libcrypto error\t[$exception]" );


exit;


END {
	eval { Net::DNS::SEC::libcrypto::croak_memory_wrap() }	# paper over crack in Devel::Cover
}


__END__

