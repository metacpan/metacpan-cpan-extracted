# $Id: 22-TSIG-verify.t 1474 2016-04-12 13:21:25Z willem $	-*-perl-*-

use strict;
use Test::More;
use Net::DNS;

my @prerequisite = qw(
		Digest::HMAC
		Digest::MD5
		Digest::SHA
		MIME::Base64
		);

foreach my $package (@prerequisite) {
	next if eval "require $package";
	plan skip_all => "$package not installed";
	exit;
}

plan tests => 28;


my $tsig = new Net::DNS::RR( type => 'TSIG' );
my $class = ref($tsig);


my $privatekey = 'Khmac-sha1.example.+161+39562.private';
END { unlink($privatekey) if defined $privatekey; }

open( KEY, ">$privatekey" ) or die "$privatekey $!";
print KEY <<'END';
Private-key-format: v1.2
Algorithm: 161 (HMAC_SHA1)
Key: xdX9m8UtQNbJUzUgQ4xDtUNZAmU=
END
close KEY;


my $publickey = 'Khmac-md5.example.+157+53335.key';
END { unlink($publickey) if defined $publickey; }

open( KEY, ">$publickey" ) or die "$publickey $!";
print KEY <<'END';
HMAC-MD5.example. IN KEY 512 3 157 ARDJZgtuTDzAWeSGYPAu9uJUkX0=
END
close KEY;


{
	my $packet = new Net::DNS::Packet('query.example');
	$packet->sign_tsig($privatekey);
	$packet->data;

	my $verified = $packet->verify();
	ok( $verified, 'verify signed packet' );
	is( ref($verified),	$class,	   'packet->verify returns TSIG' );
	is( $packet->verifyerr, 'NOERROR', 'observe packet->verifyerr' );
}


{
	my $packet = new Net::DNS::Packet('query.example');
	$packet->sign_tsig($privatekey);
	$packet->data;
	$packet->push( update => rr_add( type => 'NULL' ) );

	my $verified = $packet->verify();
	ok( !$verified, 'unverifiable signed packet' );
	is( $verified,		undef,	  'failed packet->verify returns undef' );
	is( $packet->verifyerr, 'BADSIG', 'observe packet->verifyerr' );
}


{
	my $query = new Net::DNS::Packet('query.example');
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
	my @packet = map { new Net::DNS::Packet($_) } 0 .. 3;
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
	my $packet = new Net::DNS::Packet('query.example');
	$packet->sign_tsig( $privatekey, fudge => 0 );
	my $encoded = $packet->data;
	sleep 1;

	my $query = new Net::DNS::Packet( \$encoded );
	my $verified = $query->verify();
	is( $query->verifyerr, 'BADTIME', 'unverifiable query packet: BADTIME' );
}


{
	my $packet = new Net::DNS::Packet();
	$packet->sign_tsig($privatekey);
	$packet->sigrr->error('BADTIME');
	my $encoded = $packet->data;
	my $decoded = new Net::DNS::Packet( \$encoded );
	ok( $decoded->sigrr->other, 'time appended to BADTIME response' );
}


{
	my $query = new Net::DNS::Packet('query.example');
	$query->sign_tsig($privatekey);
	$query->data;

	my $reply = $query->reply;
	$reply->sign_tsig($publickey);
	$reply->data;

	my $verified = $reply->verify($query);
	is( $reply->verifyerr, 'BADKEY', 'unverifiable reply packet: BADKEY' );
}


{
	my $packet0 = new Net::DNS::Packet();
	my $chain   = $packet0->sign_tsig($privatekey);
	$packet0->data;
	my $packet1 = new Net::DNS::Packet();
	$packet1->sign_tsig($chain);
	$packet1->data;

	my $packetx = new Net::DNS::Packet();
	$packetx->sign_tsig($publickey);
	$packetx->data;
	my $tsig     = $packetx->verify();
	my $verified = $packet1->verify($tsig);
	is( $packet1->verifyerr, 'BADKEY', 'unverifiable multi-packet: BADKEY' );
}


{
	my $packet = new Net::DNS::Packet();
	$packet->sign_tsig($publickey);
	$packet->data;
	$packet->sigrr->macbin( substr $packet->sigrr->macbin, 0, 9 );

	$packet->verify();
	is( $packet->verifyerr, 'FORMERR', 'signature too short: FORMERR' );
}


{
	my $packet = new Net::DNS::Packet();
	$packet->sign_tsig($publickey);
	$packet->data;
	my $macbin = $packet->sigrr->macbin;
	$packet->sigrr->macbin( join '', $packet->sigrr->macbin, 'x' );

	$packet->verify();
	is( $packet->verifyerr, 'FORMERR', 'signature too long: FORMERR' );
}


{
	my $packet = new Net::DNS::Packet();
	$packet->sign_tsig($privatekey);

	my $null = new Net::DNS::RR( type => 'NULL' );
	eval { $packet->sigrr->verify($null); };
	my $exception = $1 if $@ =~ /^(.+)\n/;
	ok( $exception ||= '', "unexpected argument\t[$exception]" );
}


{
	my $packet = new Net::DNS::Packet();
	$packet->sign_tsig($privatekey);

	my $null = new Net::DNS::RR( type => 'NULL' );
	eval { $packet->sigrr->verify( $packet, $null ); };
	my $exception = $1 if $@ =~ /^(.+)\n/;
	ok( $exception ||= '', "unexpected argument\t[$exception]" );
}


__END__

