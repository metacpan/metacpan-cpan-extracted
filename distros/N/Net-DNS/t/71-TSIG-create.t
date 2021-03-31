#!/usr/bin/perl
# $Id: 71-TSIG-create.t 1827 2020-12-14 10:49:27Z willem $	-*-perl-*-
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
	next if eval "require $package";## no critic
	plan skip_all => "$package not installed";
	exit;
}

plan tests => 22;


my $tsig  = Net::DNS::RR->new( type => 'TSIG' );
my $class = ref($tsig);


my $tsigkey = 'HMAC-SHA256.key';
END { unlink($tsigkey) if defined $tsigkey; }

my $fh_tsigkey = IO::File->new( $tsigkey, '>' ) || die "$tsigkey $!";
print $fh_tsigkey <<'END';
key "HMAC-SHA256.example." {
	algorithm hmac-sha256;
	secret "f+JImRXRzLpKseG+bP+W9Vwb2QAgtFuIlRU80OA3NU8=";
};
END
close($fh_tsigkey);


my $keyrr = Net::DNS::RR->new( <<'END' );			# dnssec-keygen key pair
HMAC-SHA256.example. IN KEY 512 3 163 f+JImRXRzLpKseG+bP+W9Vwb2QAgtFuIlRU80OA3NU8='
END

my $privatekey = $keyrr->privatekeyname;
END { unlink($privatekey) if defined $privatekey; }

my $publickey;
( $publickey = $privatekey ) =~ s/\.private$/\.key/;
END { unlink($publickey) if defined $publickey; }

my $fh_bindpublic = IO::File->new( $publickey, '>' ) || die "$publickey $!";
print $fh_bindpublic $keyrr->plain;
close($fh_bindpublic);


my $fh_bindprivate = IO::File->new( $privatekey, '>' ) || die "$privatekey $!";
print $fh_bindprivate <<'END';
Private-key-format: v1.2
Algorithm: 163 (HMAC_SHA256)
Key: f+JImRXRzLpKseG+bP+W9Vwb2QAgtFuIlRU80OA3NU8=
END
close($fh_bindprivate);


SKIP: {
	my $tsig = $class->create($tsigkey);
	skip( 'TSIG attribute test', 2 )
			unless is( ref($tsig), $class, 'create TSIG from BIND tsig key' );
	is( $tsig->name, $keyrr->name, 'TSIG key name' );
	my $algorithm = $tsig->algorithm;
	is( $algorithm, $tsig->algorithm( $keyrr->algorithm ), 'TSIG algorithm' );
}


SKIP: {
	my $tsig = $class->create($privatekey);
	skip( 'TSIG attribute test', 2 )
			unless is( ref($tsig), $class, 'create TSIG from BIND dnssec private key' );
	is( $tsig->name, lc( $keyrr->name ), 'TSIG key name' );
	my $algorithm = $tsig->algorithm;
	is( $algorithm, $tsig->algorithm( $keyrr->algorithm ), 'TSIG algorithm' );
}


SKIP: {
	my $tsig = $class->create($publickey);
	skip( 'TSIG attribute test', 2 )
			unless is( ref($tsig), $class, 'create TSIG from BIND dnssec public key' );
	is( $tsig->name, $keyrr->name, 'TSIG key name' );
	my $algorithm = $tsig->algorithm;
	is( $algorithm, $tsig->algorithm( $keyrr->algorithm ), 'TSIG algorithm' );
}


SKIP: {
	my $tsig = $class->create($keyrr);
	skip( 'TSIG attribute test', 2 )
			unless is( ref($tsig), $class, 'create TSIG from KEY RR' );
	is( $tsig->name, $keyrr->name, 'TSIG key name' );
	my $algorithm = $tsig->algorithm;
	is( $algorithm, $tsig->algorithm( $keyrr->algorithm ), 'TSIG algorithm' );
}


{
	my $packet = Net::DNS::Packet->new('query.example');
	$packet->sign_tsig($privatekey);
	my $tsig = $class->create($packet);
	is( ref($tsig), $class, 'create TSIG from signed packet' );
}


{
	my $chain = eval { $class->create($tsig); };
	is( ref($chain), $class, 'create successor to existing TSIG' );
}


{
	eval { $class->create(); };
	my ($exception) = split /\n/, "$@\n";
	ok( $exception, "empty argument list\t[$exception]" );
}


{
	eval { $class->create(undef); };
	my ($exception) = split /\n/, "$@\n";
	ok( $exception, "argument undefined\t[$exception]" );
}


{
	my $null = Net::DNS::RR->new( type => 'NULL' );
	eval { $class->create($null); };
	my ($exception) = split /\n/, "$@\n";
	ok( $exception, "unexpected argument\t[$exception]" );
}


{
	my $packet = Net::DNS::Packet->new('query.example');
	eval { $class->create($packet); };
	my ($exception) = split /\n/, "$@\n";
	ok( $exception, "no TSIG in packet\t[$exception]" );
}


my $dnskey = 'Kbad.example.+161+39562.key';
END { unlink($dnskey) if defined $dnskey; }

my $fh_dnskey = IO::File->new( $dnskey, '>' ) || die "$dnskey $!";
print $fh_dnskey <<'END';
HMAC-SHA1.example. IN DNSKEY 512 3 161 xdX9m8UtQNbJUzUgQ4xDtUNZAmU=
END
close($fh_dnskey);

{
	eval { $class->create($dnskey); };
	my ($exception) = split /\n/, "$@\n";
	ok( $exception, "unrecognised key format\t[$exception]" );
}


my $renamedBINDkey = 'arbitrary.key';
END { unlink($renamedBINDkey) if defined $renamedBINDkey; }

my $fh_renamed = IO::File->new( $renamedBINDkey, '>' ) || die "$renamedBINDkey $!";
print $fh_renamed <<'END';
HMAC-SHA1.example. IN KEY 512 3 161 xdX9m8UtQNbJUzUgQ4xDtUNZAmU=
END
close($fh_renamed);

my $corruptBINDkey = 'Kcorrupt.example.+161+13198.key';		# unmatched keytag
END { unlink($corruptBINDkey) if defined $corruptBINDkey; }

my $fh_corrupt = IO::File->new( $corruptBINDkey, '>' ) || die "$corruptBINDkey $!";
print $fh_corrupt <<'END';
print KEY <<'END';
HMAC-SHA1.example. IN KEY 512 3 161 xdX9m8UtQNbJUzUgQ4xDtUNZAmU=
END
close($fh_corrupt);

{
	my @warning;
	local $SIG{__WARN__} = sub { @warning = @_ };
	$class->create($renamedBINDkey);
	my ($warning) = split /\n/, "@warning\n";
	ok( $warning, "renamed BIND public key\t[$warning]" );
}


{
	my @warning;
	local $SIG{__WARN__} = sub { @warning = @_ };
	$class->create($corruptBINDkey);
	my ($warning) = split /\n/, "@warning\n";
	ok( $warning, "corrupt BIND public key\t[$warning]" );
}


{
	my @warning;
	local $SIG{__WARN__} = sub { @warning = @_ };
	$class->create( $keyrr->owner, $keyrr->key );
	my ($warning) = split /\n/, "@warning\n";
	ok( $warning, "2-argument create\t[$warning]" );
}


__END__

