#!/usr/bin/perl
# $Id: 71-TSIG-create.t 1909 2023-03-23 11:36:16Z willem $	-*-perl-*-
#

use strict;
use warnings;
use IO::File;
use Test::More;
use TestToolkit;

use Net::DNS;

my @prerequisite = qw(
		Digest::HMAC
		Digest::SHA
		MIME::Base64
		);

foreach my $package (@prerequisite) {
	next if eval "require $package";	## no critic
	plan skip_all => "$package not installed";
	exit;
}

plan tests => 18;


my $tsig  = Net::DNS::RR->new( type => 'TSIG' );
my $class = ref($tsig);


my $tsigkey = 'tsigkey.txt';
END { unlink($tsigkey) if defined $tsigkey; }

my $fh_tsigkey = IO::File->new( $tsigkey, '>' ) || die "$tsigkey $!";
print $fh_tsigkey <<'END';

Algorithm: name		; BIND dnssec-keygen private key
Key:	secret		; syntax check only

key "host1-host2.example." {	; BIND tsig-keygen key
	algorithm hmac-sha256;
	secret "f+JImRXRzLpKseG+bP+W9Vwb2QAgtFuIlRU80OA3NU8=";
};
END
close($fh_tsigkey);


for my $tsig ( $class->create($tsigkey) ) {
	is( ref($tsig), $class, 'create TSIG from BIND tsig-keygen key' );
	ok( $tsig->name,      'TSIG key name' );
	ok( $tsig->algorithm, 'TSIG algorithm' );
}


for my $packet ( Net::DNS::Packet->new('query.example') ) {
	$packet->sign_tsig($tsigkey);
	$packet->data;

	my $tsig = $class->create($packet);
	is( ref($tsig),	      $class,			 'create TSIG from packet->sigrr' );
	is( $tsig->name,      $packet->sigrr->name,	 'TSIG key name' );
	is( $tsig->algorithm, $packet->sigrr->algorithm, 'TSIG algorithm' );
}


for my $chain ( $class->create($tsig) ) {
	is( ref($chain), $class, 'create successor to existing TSIG' );
}


my $keyrr = Net::DNS::RR->new( <<'END' );			# BIND dnssec-keygen public key
host1-host2.example.	IN KEY	512 3 163 mvojlAdUskQEtC7J8OTXU5LNvt0=
END

my $dnsseckey = 'Khmac-sha256.example.+163+52011.key';
END { unlink($dnsseckey) if defined $dnsseckey; }

my $fh_dnsseckey = IO::File->new( $dnsseckey, '>' ) || die "$dnsseckey $!";
print $fh_dnsseckey $keyrr->string, "\n";
close($fh_dnsseckey);

for my $tsig ( $class->create($dnsseckey) ) {
	is( ref($tsig), $class, 'create TSIG from BIND dnssec public key' );
	ok( $tsig->name,      'TSIG key name' );
	ok( $tsig->algorithm, 'TSIG algorithm' );
}


exception( 'empty argument list', sub { $class->create() } );
exception( 'argument undefined',  sub { $class->create(undef) } );


my $null = Net::DNS::RR->new( type => 'NULL' );
exception( 'unexpected argument', sub { $class->create($null) } );

exception( '2-argument create', sub { $class->create( $keyrr->owner, $keyrr->key ) } );


my $packet = Net::DNS::Packet->new('query.example');
exception( 'no TSIG in packet', sub { $class->create($packet) } );


my $dnskey = 'Kbad.example.+161+39562.key';
END { unlink($dnskey) if defined $dnskey; }

my $fh_dnskey = IO::File->new( $dnskey, '>' ) || die "$dnskey $!";
print $fh_dnskey <<'END';
HMAC-SHA1.example. IN DNSKEY 512 3 161 xdX9m8UtQNbJUzUgQ4xDtUNZAmU=
END
close($fh_dnskey);

exception( 'unrecognised key format', sub { $class->create($dnskey) } );


my $renamedBINDkey = 'arbitrary.key';
END { unlink($renamedBINDkey) if defined $renamedBINDkey; }

my $fh_renamed = IO::File->new( $renamedBINDkey, '>' ) || die "$renamedBINDkey $!";
print $fh_renamed <<'END';
HMAC-SHA1.example. IN KEY 512 3 161 xdX9m8UtQNbJUzUgQ4xDtUNZAmU=
END
close($fh_renamed);

exception( 'renamed BIND public key', sub { $class->create($renamedBINDkey) } );


my $corruptBINDkey = 'Kcorrupt.example.+161+13198.key';		# unmatched keytag
END { unlink($corruptBINDkey) if defined $corruptBINDkey; }

my $fh_corrupt = IO::File->new( $corruptBINDkey, '>' ) || die "$corruptBINDkey $!";
print $fh_corrupt <<'END';
print KEY <<'END';
HMAC-SHA1.example. IN KEY 512 3 161 xdX9m8UtQNbJUzUgQ4xDtUNZAmU=
END
close($fh_corrupt);

exception( 'corrupt BIND public key', sub { $class->create($corruptBINDkey) } );

exit;

