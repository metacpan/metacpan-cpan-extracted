#!/usr/bin/perl
# $Id: 20-digest.t 1971 2024-04-17 09:35:43Z willem $	-*-perl-*-
#

use strict;
use warnings;
use Test::More;

my %prerequisite = ( 'Net::DNS::SEC' => 1.15, );

foreach my $package ( sort keys %prerequisite ) {
	my @revision = grep {$_} $prerequisite{$package};
	next if eval "use $package @revision; 1;";		## no critic
	plan skip_all => "missing prerequisite $package @revision";
	exit;
}

plan skip_all => 'unable to access OpenSSL libcrypto library'
		unless eval { Net::DNS::SEC::libcrypto->can('EVP_MD_CTX_new') };

plan tests => 16;


my $text = 'The quick brown fox jumps over the lazy dog';

my %digest = (
	MD5    => '9e107d9d372bb6826bd81d3542a419d6',
	SHA1   => '2fd4e1c67a2d28fced849ee1bb76e7391b93eb12',
	SHA224 => '730e109bd7a8a32b1cb9d9a09aa2325d2430587ddbc0c38bad911525',
	SHA256 => 'd7a8fbb307d7809469ca9abcb0082e4f8d5651e46d3cdb762d02d0bf37c9e592',
	SHA384 => 'ca737f1014a48f4c0b6dd43cb177b0afd9e5169367544c494011e3317dbf9a509cb1e5dc1e85a941bbee3d7f2afbc9b1',
	SHA512 => '07e547d9586f6a73f73fbac0435ed76951218fb7d0c8d788a309d785436bbb642e93a252a954f23912547d1e8a3b5ed6e1bfd7097821233fa0538f3db854fee6',
	SHA3_224 => 'd15dadceaa4d5d7bb3b48f446421d542e08ad8887305e28d58335795',
	SHA3_256 => '69070dda01975c8c120c3aada1b282394e7f032fa9cf32f4cb2259a0897dfc04',
	SHA3_384 => '7063465e08a93bce31cd89d2e3ca8f602498696e253592ed26f07bf7e703cf328581e1471a7ba7ab119b1a9ebdf8be41',
	SHA3_512 => '01dedd5de4ef14642445ba5f5b97c15e47b9ad931326e4b0727cd94cefc44fff23f07bf543139939b49128caf436dc1bdee54fcb24023a08d9403f9b4bf0d450',
	SM3	=> '5fdfe814b8573ca021983970fc79b2218c9570369b4859684e2e4c3fc76cb8ea',
			);


use_ok('Net::DNS::SEC');
use_ok('Net::DNS::SEC::Digest');

sub test {
	my ( $mnemonic, $class, @parameter ) = @_;
	my ( $head, $tail ) = unpack 'a20 a*', $text;
SKIP: {
		my $object = eval { $class->new(@parameter) };
		skip( "digest algorithm $mnemonic not supported", 2 ) unless $object;
		$object->add($text);
		is( unpack( 'H*', $object->digest ), $digest{$mnemonic}, "digest algorithm $mnemonic" );
		$object->add($head);
		$object->add($tail);
		is( unpack( 'H*', $object->digest ), $digest{$mnemonic}, "digest algorithm $mnemonic (concatenated)" );
	}
	return;
}


test( 'MD5', 'Net::DNS::SEC::Digest::MD5' );

test( 'SHA1',	'Net::DNS::SEC::Digest::SHA', 1 );

test( 'SHA224', 'Net::DNS::SEC::Digest::SHA', 224 );
test( 'SHA256', 'Net::DNS::SEC::Digest::SHA', 256 );
test( 'SHA384', 'Net::DNS::SEC::Digest::SHA', 384 );
test( 'SHA512', 'Net::DNS::SEC::Digest::SHA', 512 );

test( 'SM3', 'Net::DNS::SEC::Digest::SM3' );

exit;

__END__

