#!/usr/bin/perl
# $Id: 72-TSIG-verify.t 1856 2021-12-02 14:36:25Z willem $	-*-perl-*-
#

use strict;
use warnings;
use IO::File;
use Test::More;
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

plan tests => 28;


my $tsig  = Net::DNS::RR->new( type => 'TSIG' );
my $class = ref($tsig);


my $privatekey = 'Khmac-sha1.example.+161+39562.private';
END { unlink($privatekey) if defined $privatekey; }

my $fh_private = IO::File->new( $privatekey, '>' ) || die "$privatekey $!";
print $fh_private <<'END';
Private-key-format: v1.2
Algorithm: 161 (HMAC_SHA1)
Key: xdX9m8UtQNbJUzUgQ4xDtUNZAmU=
END
close($fh_private);


my $publickey = 'Khmac-md5.example.+157+53335.key';
END { unlink($publickey) if defined $publickey; }

my $fh_public = IO::File->new( $publickey, '>' ) || die "$publickey $!";
print $fh_public <<'END';
HMAC-MD5.example. IN KEY 512 3 157 ARDJZgtuTDzAWeSGYPAu9uJUkX0=
END
close($fh_public);


{
	my $packet = Net::DNS::Packet->new('query.example');
	$packet->sign_tsig($privatekey);
	$packet->data;

	my $verified = $packet->verify();
	ok( $verified, 'verify signed packet' );
	is( ref($verified),	$class,	   'packet->verify returns TSIG' );
	is( $packet->verifyerr, 'NOERROR', 'observe packet->verifyerr' );
}


{
	my $packet = Net::DNS::Packet->new('query.example');
	$packet->sign_tsig($privatekey);
	$packet->data;
	$packet->push( update => rr_add( type => 'NULL' ) );

	my $verified = $packet->verify();
	ok( !$verified, 'unverifiable signed packet' );
	is( $verified,		undef,	  'failed packet->verify returns undef' );
	is( $packet->verifyerr, 'BADSIG', 'observe packet->verifyerr' );
}


{
	my $query = Net::DNS::Packet->new('query.example');
	$query->sign_tsig($privatekey);
	$query->data;

	my $reply = $query->reply;
	$reply->sign_tsig($query);
	$reply->data;

	my $verified = $reply->verify($query);
	ok( $verified, 'verify reply packet' );
	is( $reply->verifyerr, 'NOERROR', 'observe packet->verifyerr' );
}


{
	my @packet = map { Net::DNS::Packet->new($_) } 0 .. 3;
	my $signed = $privatekey;
	foreach my $packet (@packet) {
		$signed = $packet->sign_tsig($signed);
		$packet->data;
		is( ref($signed), $class, 'sign multi-packet' );
	}

	my @verified;
	foreach my $packet (@packet) {
		my ($verified) = $packet->verify(@verified);
		@verified = ($verified);
		ok( $verified, 'verify multi-packet' );
	}

	my @state;
	$packet[2]->sigrr->fudge(0);
	foreach my $packet (@packet) {
		my $tsig = $packet->verify(@state);
		@state = ($tsig);
		my $result = $packet->verifyerr;
		ok( $result, "unverifiable multi-packet: $result" );
	}
}


{
	my $packet = Net::DNS::Packet->new('query.example');
	$packet->sign_tsig( $privatekey, fudge => 0 );
	my $encoded = $packet->data;
	sleep 2;						# guarantee one complete second delay

	my $query = Net::DNS::Packet->new( \$encoded );
	$query->verify();
	is( $query->verifyerr, 'BADTIME', 'unverifiable query packet: BADTIME' );
}


{
	my $packet = Net::DNS::Packet->new();
	$packet->sign_tsig($privatekey);
	$packet->sigrr->error('BADTIME');
	my $encoded = $packet->data;
	my $decoded = Net::DNS::Packet->new( \$encoded );
	ok( $decoded->sigrr->other, 'time appended to BADTIME response' );
}


{
	my $query = Net::DNS::Packet->new('query.example');
	$query->sign_tsig($privatekey);
	$query->data;

	my $reply = $query->reply;
	$reply->sign_tsig($publickey);
	$reply->data;

	my $verified = $reply->verify($query);
	is( $reply->verifyerr, 'BADKEY', 'unverifiable reply packet: BADKEY' );
}


{
	my $packet0 = Net::DNS::Packet->new();
	my $chain   = $packet0->sign_tsig($privatekey);
	$packet0->data;
	my $packet1 = Net::DNS::Packet->new();
	$packet1->sign_tsig($chain);
	$packet1->data;

	my $packetx = Net::DNS::Packet->new();
	$packetx->sign_tsig($publickey);
	$packetx->data;
	my $tsig     = $packetx->verify();
	my $verified = $packet1->verify($tsig);
	is( $packet1->verifyerr, 'BADKEY', 'unverifiable multi-packet: BADKEY' );
}


{
	my $packet = Net::DNS::Packet->new();
	$packet->sign_tsig($publickey);
	$packet->data;
	$packet->sigrr->macbin( substr $packet->sigrr->macbin, 0, 9 );

	$packet->verify();
	is( $packet->verifyerr, 'BADTRUNC', 'signature too short: BADTRUNC' );
}


{
	my $packet = Net::DNS::Packet->new();
	$packet->sign_tsig($publickey);
	$packet->data;
	my $macbin = $packet->sigrr->macbin;
	$packet->sigrr->macbin( join '', $packet->sigrr->macbin, 'x' );

	$packet->verify();
	is( $packet->verifyerr, 'BADTRUNC', 'signature too long: BADTRUNC' );
}


{
	my $packet = Net::DNS::Packet->new();
	$packet->sign_tsig($privatekey);

	my $null = Net::DNS::RR->new( type => 'NULL' );
	eval { $packet->sigrr->verify($null); };
	my ($exception) = split /\n/, "$@\n";
	ok( $exception, "unexpected argument\t[$exception]" );
}


{
	my $packet = Net::DNS::Packet->new();
	$packet->sign_tsig($privatekey);

	my $null = Net::DNS::RR->new( type => 'NULL' );
	eval { $packet->sigrr->verify( $packet, $null ); };
	my ($exception) = split /\n/, "$@\n";
	ok( $exception, "unexpected argument\t[$exception]" );
}


__END__

