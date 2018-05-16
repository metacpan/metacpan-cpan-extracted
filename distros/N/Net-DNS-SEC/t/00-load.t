# $Id: 00-load.t 1669 2018-04-27 10:17:13Z willem $
#

use strict;
use Test::More tests => 2;

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
	push @diag, sprintf "%-25s  %s", $module, $version;
}
diag join "\n\t", @diag;


ok( eval { Net::DNS::SEC::libcrypto->VERSION }, 'XS component SEC.xs loaded' )
		|| BAIL_OUT "Unable to access OpenSSL libcrypto library";

use_ok('Net::DNS::SEC');


exit;

__END__

