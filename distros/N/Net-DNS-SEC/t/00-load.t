# $Id: 00-load.t 1646 2018-03-12 12:52:45Z willem $
#

use strict;
use Test::More tests => 2;

my @module = qw(
	Net::DNS::SEC
	Net::DNS::SEC::DSA
	Net::DNS::SEC::ECDSA
	Net::DNS::SEC::EdDSA
	Net::DNS::SEC::RSA
	Net::DNS::SEC::Keyset
	Net::DNS::SEC::Private
	Net::DNS::SEC::libcrypto
	Crypt::OpenSSL::Bignum
	Crypt::OpenSSL::EC
	Crypt::OpenSSL::ECDSA
	Digest::GOST
	Digest::SHA
	File::Find
	File::Spec
	IO::File
	MIME::Base64
	Net::DNS
	Test::More
	);


# GOST R 34.10-2001 and GOST R 34.11-94 superseded by
# GOST R 34.10-2012 and GOST R 34.11-2012 respectively.
push @module, qw(Net::DNS::SEC::ECCGOST) if eval 'require Digest::GOST';


my @diag = "\nThese tests were run using:";
foreach my $module ( sort @module ) {
	eval "require $module";
	my $version = eval { $module->VERSION } || next;
	push @diag, sprintf "%-25s  %s", $module, $version;
}
diag join "\n\t", @diag;


ok( eval { Net::DNS::SEC::libcrypto->VERSION }, 'XS component SEC.xs loaded' )
		|| BAIL_OUT "Unable to access OpenSSL libcrypto library";

use_ok('Net::DNS::SEC');


exit;

__END__

