#!/usr/bin/perl
# $Id: 72-TSIG-verify.t 1980 2024-06-02 10:16:33Z willem $	-*-perl-*-
#

use strict;
use warnings;
use IO::File;
use Test::More;
use TestToolkit;

use Net::DNS;

my @prerequisite = qw(
		Digest::HMAC
		Digest::MD5
		Digest::SHA
		MIME::Base64
		);

foreach my $package (@prerequisite) {
	next if eval "require $package";	## no critic
	plan skip_all => "$package not installed";
	exit;
}

plan tests => 26;


my $tsig  = Net::DNS::RR->new( type => 'TSIG' );
my $class = ref($tsig);


my $tsigkey = 'tsigkey.txt';
END { unlink($tsigkey) if defined $tsigkey; }

my $fh_tsigkey = IO::File->new( $tsigkey, '>' ) || die "$tsigkey $!";
print $fh_tsigkey <<'END';
key "host1-host2.example." {
	algorithm hmac-sha256;
	secret "f+JImRXRzLpKseG+bP+W9Vwb2QAgtFuIlRU80OA3NU8=";
};
END
close($fh_tsigkey);


for my $packet ( Net::DNS::Packet->new('query.example') ) {
	$packet->sign_tsig($tsigkey);
	$packet->encode;

	my $verified  = $packet->verify();
	my $verifyerr = $packet->verifyerr();
	ok( $verified, "verify signed packet	$verifyerr" );
	is( ref($verified), $class, 'packet->verify returns TSIG' );
}


for my $packet ( Net::DNS::Packet->new('query.example') ) {
	$packet->sign_tsig($tsigkey);
	$packet->encode;
	$packet->push( update => rr_add( type => 'NULL' ) );

	my $verified  = $packet->verify();
	my $verifyerr = $packet->verifyerr();
	ok( !$verified, "verify corrupt packet	$verifyerr" );
	is( $verified, undef, 'packet->verify returns undef' );
}


for my $query ( Net::DNS::Packet->new('query.example') ) {
	$query->sign_tsig($tsigkey);
	$query->encode;

	my $reply = $query->reply;
	$reply->sign_tsig($query);
	$reply->encode;

	my $verified  = $reply->verify($query);
	my $verifyerr = $reply->verifyerr();
	ok( $verified, "verify reply packet	$verifyerr" );
}


{
	my @packet = map { Net::DNS::Packet->new($_) } ( 0 .. 3 );
	my $signed = $tsigkey;
	foreach my $packet (@packet) {
		$signed = $packet->sign_tsig($signed);
		$packet->encode;
		is( ref($signed), $class, 'sign multi-packet' );
	}

	my @verified;
	foreach my $packet (@packet) {
		@verified = $packet->verify(@verified);
		my ($verified) = @verified;
		my $verifyerr = $packet->verifyerr();
		ok( $verified, "verify multi-packet	$verifyerr" );
	}

	my @unverifiable;
	$packet[2]->sigrr->fudge(0);
	foreach my $packet (@packet) {
		@unverifiable = $packet->verify(@unverifiable);
		my $verifyerr = $packet->verifyerr();
		ok( 1, "verify corrupt multi-packet	$verifyerr" );
	}
	my ($verified) = @unverifiable;
	is( $verified, undef, 'final packet->verify returns undef' );
}


for my $packet ( Net::DNS::Packet->new('query.example') ) {
	$packet->sign_tsig( $tsigkey, fudge => 0 );
	my $encoded = $packet->encode;
	sleep 2;						# guarantee one complete second delay

	my $query = Net::DNS::Packet->new( \$encoded );
	$query->verify();
	is( $query->verifyerr, 'BADTIME', 'unverifiable query packet: BADTIME' );
}


for my $packet ( Net::DNS::Packet->new() ) {
	$packet->sign_tsig($tsigkey);
	$packet->sigrr->error('BADTIME');
	my $encoded = $packet->encode;
	my $decoded = Net::DNS::Packet->new( \$encoded );
	ok( $decoded->sigrr->other, 'time appended to BADTIME response' );
}


for my $query ( Net::DNS::Packet->new('query.example') ) {
	$query->sign_tsig($tsigkey);
	$query->encode;

	my $reply = $query->reply;
	$reply->sign_tsig($query);
	$reply->encode;
	$reply->sigrr->algorithm('hmac-sha1');

	my $verified  = $reply->verify($query);
	my $verifyerr = $reply->verifyerr();
	ok( !$verified, "mismatched verify keys	$verifyerr" );
}


for my $packet ( Net::DNS::Packet->new('query.example') ) {
	$packet->sign_tsig($tsigkey);
	$packet->encode;

	my $tsig = $packet->reply->sign_tsig($tsigkey);
	$tsig->algorithm('hmac-sha1');

	my $verified  = $packet->verify($tsig);
	my $verifyerr = $packet->verifyerr();
	ok( !$verified, "mismatched verify keys	$verifyerr" );
}


for my $packet ( Net::DNS::Packet->new() ) {
	$packet->sign_tsig($tsigkey);
	$packet->encode;
	$packet->sigrr->macbin( substr $packet->sigrr->macbin, 0, 9 );

	$packet->verify();
	is( $packet->verifyerr, 'BADTRUNC', 'signature too short: BADTRUNC' );
}


for my $packet ( Net::DNS::Packet->new() ) {
	$packet->sign_tsig($tsigkey);
	$packet->encode;
	my $macbin = $packet->sigrr->macbin;
	$packet->sigrr->macbin( join '', $packet->sigrr->macbin, 'x' );

	$packet->verify();
	is( $packet->verifyerr, 'BADTRUNC', 'signature too long: BADTRUNC' );
}


for my $packet ( Net::DNS::Packet->new() ) {
	$packet->sign_tsig($tsigkey);
	my $null = Net::DNS::RR->new( type => 'NULL' );

	exception( 'unexpected argument', sub { $packet->sigrr->verify($null) } );
	exception( 'unexpected argument', sub { $packet->sigrr->verify( $packet, $null ) } );
}

exit;

