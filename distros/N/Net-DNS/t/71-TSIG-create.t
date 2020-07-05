# $Id: 71-TSIG-create.t 1786 2020-06-15 15:05:47Z willem $	-*-perl-*-

use strict;
use Test::More;
use Net::DNS;

my %prerequisite = (
	'Digest::HMAC' => 1.03,
	'Digest::MD5'  => 2.13,
	'Digest::SHA'  => 5.23,
	'MIME::Base64' => 2.13,
	);

foreach my $package ( sort keys %prerequisite ) {
	my @revision = grep $_, $prerequisite{$package};
	next if eval "use $package @revision; 1;";
	plan skip_all => "missing prerequisite $package @revision";
	exit;
}

plan tests => 22;


my $tsig  = new Net::DNS::RR( type => 'TSIG' );
my $class = ref($tsig);


my $tsigkey = 'HMAC-SHA256.key';
END { unlink($tsigkey) if defined $tsigkey; }

open( KEY, '>', $tsigkey ) or die "$tsigkey $!";
print KEY <<'END';
key "HMAC-SHA256.example." {
	algorithm hmac-sha256;
	secret "f+JImRXRzLpKseG+bP+W9Vwb2QAgtFuIlRU80OA3NU8=";
};
END
close KEY;


my $keyrr = new Net::DNS::RR <<'END';				# dnssec-keygen key pair
HMAC-SHA256.example. IN KEY 512 3 163 f+JImRXRzLpKseG+bP+W9Vwb2QAgtFuIlRU80OA3NU8=
END

my $privatekey = $keyrr->privatekeyname;
END { unlink($privatekey) if defined $privatekey; }

my $publickey;
( $publickey = $privatekey ) =~ s/\.private$/\.key/;
END { unlink($publickey) if defined $publickey; }

open( KEY, ">", $publickey ) or die "$publickey $!";
print KEY $keyrr->plain;
close KEY;


open( KEY, ">", $privatekey ) or die "$privatekey $!";
print KEY <<'END';
Private-key-format: v1.2
Algorithm: 163 (HMAC_SHA256)
Key: f+JImRXRzLpKseG+bP+W9Vwb2QAgtFuIlRU80OA3NU8=
END
close KEY;


SKIP: {
	my $tsig = create $class($tsigkey);
	skip( 'TSIG attribute test', 2 )
			unless is( ref($tsig), $class, 'create TSIG from BIND tsig key' );
	is( $tsig->name, $keyrr->name, 'TSIG key name' );
	my $algorithm = $tsig->algorithm;
	is( $algorithm, $tsig->algorithm( $keyrr->algorithm ), 'TSIG algorithm' );
}


SKIP: {
	my $tsig = create $class($privatekey);
	skip( 'TSIG attribute test', 2 )
			unless is( ref($tsig), $class, 'create TSIG from BIND dnssec private key' );
	is( $tsig->name, lc( $keyrr->name ), 'TSIG key name' );
	my $algorithm = $tsig->algorithm;
	is( $algorithm, $tsig->algorithm( $keyrr->algorithm ), 'TSIG algorithm' );
}


SKIP: {
	my $tsig = create $class($publickey);
	skip( 'TSIG attribute test', 2 )
			unless is( ref($tsig), $class, 'create TSIG from BIND dnssec public key' );
	is( $tsig->name, $keyrr->name, 'TSIG key name' );
	my $algorithm = $tsig->algorithm;
	is( $algorithm, $tsig->algorithm( $keyrr->algorithm ), 'TSIG algorithm' );
}


SKIP: {
	my $tsig = create $class($keyrr);
	skip( 'TSIG attribute test', 2 )
			unless is( ref($tsig), $class, 'create TSIG from KEY RR' );
	is( $tsig->name, $keyrr->name, 'TSIG key name' );
	my $algorithm = $tsig->algorithm;
	is( $algorithm, $tsig->algorithm( $keyrr->algorithm ), 'TSIG algorithm' );
}


{
	my $packet = new Net::DNS::Packet('query.example');
	$packet->sign_tsig($privatekey);
	my $tsig = create $class($packet);
	is( ref($tsig), $class, 'create TSIG from signed packet' );
}


{
	my $chain = eval { create $class($tsig); };
	is( ref($chain), $class, 'create successor to existing TSIG' );
}


{
	eval { create $class(); };
	my ($exception) = split /\n/, "$@\n";
	ok( $exception, "empty argument list\t[$exception]" );
}


{
	eval { create $class(undef); };
	my ($exception) = split /\n/, "$@\n";
	ok( $exception, "argument undefined\t[$exception]" );
}


{
	my $null = new Net::DNS::RR( type => 'NULL' );
	eval { create $class($null); };
	my ($exception) = split /\n/, "$@\n";
	ok( $exception, "unexpected argument\t[$exception]" );
}


{
	my $packet = new Net::DNS::Packet('query.example');
	eval { create $class($packet); };
	my ($exception) = split /\n/, "$@\n";
	ok( $exception, "no TSIG in packet\t[$exception]" );
}


my $dnskey = 'Kbad.example.+161+39562.key';
END { unlink($dnskey) if defined $dnskey; }

open( KEY, ">", $dnskey ) or die "$dnskey $!";
print KEY <<'END';
HMAC-SHA1.example. IN DNSKEY 512 3 161 xdX9m8UtQNbJUzUgQ4xDtUNZAmU=
END
close KEY;

{
	eval { create $class($dnskey); };
	my ($exception) = split /\n/, "$@\n";
	ok( $exception, "unrecognised key format\t[$exception]" );
}


my $renamedBINDkey = 'arbitrary.key';
END { unlink($renamedBINDkey) if defined $renamedBINDkey; }

open( KEY, ">", $renamedBINDkey ) or die "$renamedBINDkey $!";
print KEY <<'END';
HMAC-SHA1.example. IN KEY 512 3 161 xdX9m8UtQNbJUzUgQ4xDtUNZAmU=
END
close KEY;

my $corruptBINDkey = 'Kcorrupt.example.+161+13198.key';		# unmatched keytag
END { unlink($corruptBINDkey) if defined $corruptBINDkey; }

open( KEY, ">", $corruptBINDkey ) or die "$corruptBINDkey $!";
print KEY <<'END';
HMAC-SHA1.example. IN KEY 512 3 161 xdX9m8UtQNbJUzUgQ4xDtUNZAmU=
END
close KEY;

{
	my @warning;
	local $SIG{__WARN__} = sub { @warning = @_ };
	create $class($renamedBINDkey);
	my ($warning) = split /\n/, "@warning\n";
	ok( $warning, "renamed BIND public key\t[$warning]" );
}


{
	my @warning;
	local $SIG{__WARN__} = sub { @warning = @_ };
	create $class($corruptBINDkey);
	my ($warning) = split /\n/, "@warning\n";
	ok( $warning, "corrupt BIND public key\t[$warning]" );
}


{
	my @warning;
	local $SIG{__WARN__} = sub { @warning = @_ };
	create $class( $keyrr->owner, $keyrr->key );
	my ($warning) = split /\n/, "@warning\n";
	ok( $warning, "2-argument create\t[$warning]" );
}


__END__

