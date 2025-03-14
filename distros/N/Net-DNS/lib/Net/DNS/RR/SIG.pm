package Net::DNS::RR::SIG;

use strict;
use warnings;
our $VERSION = (qw$Id: SIG.pm 2003 2025-01-21 12:06:06Z willem $)[2];

use base qw(Net::DNS::RR);


=head1 NAME

Net::DNS::RR::SIG - DNS SIG resource record

=cut

use integer;

use Carp;
use Time::Local;

use Net::DNS::Parameters qw(:type);

use constant DEBUG => 0;

use constant UTIL => defined eval { require Scalar::Util; };

eval { require MIME::Base64 };

## IMPORTANT: MUST NOT include crypto packages in metadata (strong crypto prohibited in many territories)
use constant DNSSEC => defined $INC{'Net/DNS/SEC.pm'};	## Discover how we got here, without exposing any crypto

my @index;
if (DNSSEC) {
	foreach my $class ( map {"Net::DNS::SEC::$_"} qw(Private RSA DSA ECDSA EdDSA Digest SM2) ) {
		my @algorithms = eval join '', qw(r e q u i r e), " $class; ${class}::_index()";	## no critic
		push @index, map { ( $_ => $class ) } @algorithms;
	}
	croak 'Net::DNS::SEC version not supported' unless scalar(@index);
}

my %DNSSEC_verify = @index;
my %DNSSEC_siggen = @index;

my @field = qw(typecovered algorithm labels orgttl sigexpiration siginception keytag);


sub _decode_rdata {			## decode rdata from wire-format octet string
	my ( $self, $data, $offset, @opaque ) = @_;

	my $limit = $offset + $self->{rdlength};
	@{$self}{@field} = unpack "\@$offset n C2 N3 n", $$data;
	( $self->{signame}, $offset ) = Net::DNS::DomainName->decode( $data, $offset + 18, @opaque );
	$self->{sigbin} = substr $$data, $offset, $limit - $offset;

	croak('misplaced or corrupt SIG') unless $limit == length $$data;
	my $raw = substr $$data, 0, $self->{offset}++;
	$self->{rawref} = \$raw;
	return;
}


sub _encode_rdata {			## encode rdata as wire-format octet string
	my ( $self, $offset, @opaque ) = @_;

	my $signame = $self->{signame};

	if ( DNSSEC && !$self->{sigbin} ) {
		my ( undef, $packet ) = @opaque;
		my $private = delete $self->{private};		# one shot is all you get
		my $sigdata = $self->_CreateSigData($packet);
		$self->_CreateSig( $sigdata, $private || die 'missing key reference' );
	}

	return pack 'n C2 N3 n a* a*', @{$self}{@field}, $signame->canonical, $self->sigbin;
}


sub _format_rdata {			## format rdata portion of RR string.
	my $self = shift;

	my $sname = $self->{signame} || return '';
	my @sig64 = split /\s+/, MIME::Base64::encode( $self->sigbin );
	my @rdata = ( map( { $self->$_ } @field ), $sname->string, @sig64 );
	return @rdata;
}


sub _parse_rdata {			## populate RR from rdata in argument list
	my ( $self, @argument ) = @_;

	foreach ( @field, qw(signame) ) { $self->$_( shift @argument ) }
	$self->signature(@argument);
	return;
}


sub _defaults {				## specify RR attribute default values
	my $self = shift;

	$self->class('ANY');
	$self->typecovered('TYPE0');
	$self->algorithm(1);
	$self->labels(0);
	$self->orgttl(0);
	$self->sigval(10);
	return;
}


sub typecovered {
	my ( $self, @value ) = @_;				# uncoverable pod
	for (@value) { $self->{typecovered} = typebyname($_) }
	my $typecode = $self->{typecovered};
	return defined $typecode ? typebyval($typecode) : undef;
}


sub algorithm {
	my ( $self, $arg ) = @_;

	unless ( ref($self) ) {		## class method or simple function
		my $argn = pop;
		return $argn =~ /[^0-9]/ ? _algbyname($argn) : _algbyval($argn);
	}

	return $self->{algorithm} unless defined $arg;
	return _algbyval( $self->{algorithm} ) if $arg =~ /MNEMONIC/i;
	return $self->{algorithm} = _algbyname($arg);
}


sub labels {
	return shift->{labels} = 0;				# uncoverable pod
}


sub orgttl {
	return shift->{orgttl} = 0;				# uncoverable pod
}


sub sigexpiration {
	my ( $self, @value ) = @_;
	for (@value) { $self->{sigexpiration} = _string2time($_) }
	my $time = $self->{sigexpiration};
	return unless defined wantarray && defined $time;
	return UTIL ? Scalar::Util::dualvar( $time, _time2string($time) ) : _time2string($time);
}

sub siginception {
	my ( $self, @value ) = @_;
	for (@value) { $self->{siginception} = _string2time($_) }
	my $time = $self->{siginception};
	return unless defined wantarray && defined $time;
	return UTIL ? Scalar::Util::dualvar( $time, _time2string($time) ) : _time2string($time);
}

sub sigex { return &sigexpiration; }	## historical

sub sigin { return &siginception; }	## historical

sub sigval {
	my ( $self, @value ) = @_;
	no integer;
	( $self->{sigval} ) = map { int( 60.0 * $_ ) } @value;
	return;
}


sub keytag {
	my ( $self, @value ) = @_;
	for (@value) { $self->{keytag} = 0 + $_ }
	return $self->{keytag} || 0;
}


sub signame {
	my ( $self, @value ) = @_;
	for (@value) { $self->{signame} = Net::DNS::DomainName2535->new($_) }
	return $self->{signame} ? $self->{signame}->name : undef;
}


sub sig {
	my ( $self, @value ) = @_;
	return MIME::Base64::encode( $self->sigbin(), "" ) unless scalar @value;
	return $self->sigbin( MIME::Base64::decode( join "", @value ) );
}


sub sigbin {
	my ( $self, @value ) = @_;
	for (@value) { $self->{sigbin} = $_ }
	return $self->{sigbin} || "";
}


sub signature { return &sig; }


sub create {
	unless (DNSSEC) {
		croak qq[No "use Net::DNS::SEC" declaration in application code];
	} else {
		my ( $class, $data, $priv_key, %etc ) = @_;

		my $private = ref($priv_key) ? $priv_key : ( Net::DNS::SEC::Private->new($priv_key) );
		croak 'Unable to parse private key' unless ref($private) eq 'Net::DNS::SEC::Private';

		my $self = Net::DNS::RR->new(
			type	     => 'SIG',
			typecovered  => 'TYPE0',
			siginception => time(),
			algorithm    => $private->algorithm,
			keytag	     => $private->keytag,
			signame	     => $private->signame,
			);

		while ( my ( $attribute, $value ) = each %etc ) {
			$self->$attribute($value);
		}

		$self->{sigexpiration} = $self->{siginception} + $self->{sigval}
				unless $self->{sigexpiration};

		$self->_CreateSig( $self->_CreateSigData($data), $private ) if $data;

		$self->{private} = $private unless $data;	# mark packet for SIG0 generation
		return $self;
	}
}


sub verify {

	# Reminder...

	# $dataref may be either a data string or a reference to a
	# Net::DNS::Packet object.
	#
	# $keyref is either a key object or a reference to an array
	# of keys.

	unless (DNSSEC) {
		croak qq[No "use Net::DNS::SEC" declaration in application code];
	} else {
		my ( $self, $dataref, $keyref ) = @_;

		if ( my $isa = ref($dataref) ) {
			print '$dataref argument is ', $isa, "\n" if DEBUG;
			croak '$dataref must be scalar or a Net::DNS::Packet'
					unless $isa =~ /Net::DNS/ && $dataref->isa('Net::DNS::Packet');
		}

		print '$keyref argument is of class ', ref($keyref), "\n" if DEBUG;
		if ( ref($keyref) eq "ARRAY" ) {

			#  We will iterate over the supplied key list and
			#  return when there is a successful verification.
			#  If not, continue so that we survive key-id collision.

			print "Iterating over ", scalar(@$keyref), " keys\n" if DEBUG;
			my @error;
			foreach my $keyrr (@$keyref) {
				my $result = $self->verify( $dataref, $keyrr );
				return $result if $result;
				my $error = $self->{vrfyerrstr};
				my $keyid = $keyrr->keytag;
				push @error, "key $keyid: $error";
				print "key $keyid: $error\n" if DEBUG;
				next;
			}

			$self->{vrfyerrstr} = join "\n", @error;
			return 0;

		} elsif ( $keyref->isa('Net::DNS::RR::DNSKEY') ) {

			print "Validating using key with keytag: ", $keyref->keytag, "\n" if DEBUG;

		} else {
			croak join ' ', ref($keyref), 'can not be used as SIG0 key';
		}

		croak "SIG typecovered is TYPE$self->{typecovered}" if $self->{typecovered};

		if (DEBUG) {
			print "\n ---------------------- SIG DEBUG ----------------------";
			print "\n  SIG:\t", $self->string;
			print "\n  KEY:\t", $keyref->string;
			print "\n -------------------------------------------------------\n";
		}

		$self->{vrfyerrstr} = '';
		unless ( $self->algorithm == $keyref->algorithm ) {
			$self->{vrfyerrstr} = 'algorithm does not match';
			return 0;
		}

		unless ( $self->keytag == $keyref->keytag ) {
			$self->{vrfyerrstr} = 'keytag does not match';
			return 0;
		}

		# The data that is to be verified
		my $sigdata = $self->_CreateSigData($dataref);

		my $verified = $self->_VerifySig( $sigdata, $keyref ) || return 0;

		# time to do some time checking.
		my $t = time;

		if ( _ordered( $self->{sigexpiration}, $t ) ) {
			$self->{vrfyerrstr} = join ' ', 'Signature expired at', $self->sigexpiration;
			return 0;
		} elsif ( _ordered( $t, $self->{siginception} ) ) {
			$self->{vrfyerrstr} = join ' ', 'Signature valid from', $self->siginception;
			return 0;
		}

		return 1;
	}
}								#END verify


sub vrfyerrstr {
	return shift->{vrfyerrstr};
}


########################################

{
	my @algbyname = (
		'DELETE'	     => 0,			# [RFC4034][RFC4398][RFC8078]
		'RSAMD5'	     => 1,			# [RFC3110][RFC4034]
		'DH'		     => 2,			# [RFC2539]
		'DSA'		     => 3,			# [RFC3755][RFC2536]
					## Reserved	=> 4,	# [RFC6725]
		'RSASHA1'	     => 5,			# [RFC3110][RFC4034]
		'DSA-NSEC3-SHA1'     => 6,			# [RFC5155]
		'RSASHA1-NSEC3-SHA1' => 7,			# [RFC5155]
		'RSASHA256'	     => 8,			# [RFC5702]
					## Reserved	=> 9,	# [RFC6725]
		'RSASHA512'	     => 10,			# [RFC5702]
					## Reserved	=> 11,	# [RFC6725]
		'ECC-GOST'	     => 12,			# [RFC5933]
		'ECDSAP256SHA256'    => 13,			# [RFC6605]
		'ECDSAP384SHA384'    => 14,			# [RFC6605]
		'ED25519'	     => 15,			# [RFC8080]
		'ED448'		     => 16,			# [RFC8080]
		'SM2SM3'	     => 17,			# [RFC-cuiling-dnsop-sm2-alg-15]
		'ECC-GOST12'	     => 23,			# [RFC-makarenko-gost2012-dnssec-05]

		'INDIRECT'   => 252,				# [RFC4034]
		'PRIVATEDNS' => 253,				# [RFC4034]
		'PRIVATEOID' => 254,				# [RFC4034]
					## Reserved	=> 255,	# [RFC4034]
		);

	my %algbyval = reverse @algbyname;

	foreach (@algbyname) { s/[\W_]//g; }			# strip non-alphanumerics
	my @algrehash = map { /^\d/ ? ($_) x 3 : uc($_) } @algbyname;
	my %algbyname = @algrehash;				# work around broken cperl

	sub _algbyname {
		my $arg = shift;
		my $key = uc $arg;				# synthetic key
		$key =~ s/[\W_]//g;				# strip non-alphanumerics
		my $val = $algbyname{$key};
		return $val if defined $val;
		return $key =~ /^\d/ ? $arg : croak qq[unknown algorithm $arg];
	}

	sub _algbyval {
		my $value = shift;
		return $algbyval{$value} || return $value;
	}
}


{
	my %siglen = (
		1  => 128,
		3  => 41,
		5  => 256,
		6  => 41,
		7  => 256,
		8  => 256,
		10 => 256,
		12 => 64,
		13 => 64,
		14 => 96,
		15 => 64,
		16 => 114,
		);

	sub _size {			## estimate encoded size
		my $self  = shift;
		my $clone = bless {%$self}, ref($self);		# shallow clone
		$clone->sigbin( 'x' x $siglen{$self->algorithm} );
		return length $clone->encode();
	}
}


sub _CreateSigData {
	if (DNSSEC) {
		my ( $self, $message ) = @_;

		if ( ref($message) ) {
			die 'missing packet reference' unless $message->isa('Net::DNS::Packet');
			my @unsigned = grep { ref($_) ne ref($self) } @{$message->{additional}};
			local $message->{additional} = \@unsigned;    # remake header image
			my @part = qw(question answer authority additional);
			my @size = map { scalar @{$message->{$_}} } @part;
			my $rref = delete $self->{rawref};
			my $data = $rref ? $$rref : $message->encode;
			my ( $id, $status ) = unpack 'n2', $data;
			my $hbin = pack 'n6 a*', $id, $status, @size;
			$message = $hbin . substr $data, length $hbin;
		}

		my $sigdata = pack 'n C2 N3 n a*', @{$self}{@field}, $self->{signame}->encode;
		print "\npreamble\t", unpack( 'H*', $sigdata ), "\nrawdata\t", unpack( 'H100', $message ), " ...\n"
				if DEBUG;
		return join '', $sigdata, $message;
	}
}


sub _CreateSig {
	if (DNSSEC) {
		my ( $self, @argument ) = @_;

		my $algorithm = $self->algorithm;
		return eval {
			my $class = $DNSSEC_siggen{$algorithm};
			die "algorithm $algorithm not supported\n" unless $class;
			$self->sigbin( $class->sign(@argument) );
		} || return croak "${@}signature generation failed";
	}
}


sub _VerifySig {
	if (DNSSEC) {
		my ( $self, @argument ) = @_;

		my $algorithm = $self->algorithm;
		my $returnval = eval {
			my $class = $DNSSEC_verify{$algorithm};
			die "algorithm $algorithm not supported\n" unless $class;
			$class->verify( @argument, $self->sigbin );
		};

		unless ($returnval) {
			$self->{vrfyerrstr} = "${@}signature verification failed";
			print "\n", $self->{vrfyerrstr}, "\n" if DEBUG;
			return 0;
		}

		# uncoverable branch true	# unexpected return value from EVP_DigestVerify
		croak "internal error in algorithm $algorithm verification" unless $returnval == 1;
		print "\nalgorithm $algorithm verification successful\n" if DEBUG;
		return $returnval;
	}
}


sub _ordered() {			## irreflexive 32-bit partial ordering
	my ( $n1, $n2 ) = @_;

	return 0 unless defined $n2;				# ( any, undef )
	return 1 unless defined $n1;				# ( undef, any )

	# unwise to assume 64-bit arithmetic, or that 32-bit integer overflow goes unpunished
	use integer;						# fold, leaving $n2 non-negative
	$n1 = ( $n1 & 0xFFFFFFFF ) ^ ( $n2 & 0x80000000 );	# -2**31 <= $n1 < 2**32
	$n2 = ( $n2 & 0x7FFFFFFF );				#  0	 <= $n2 < 2**31

	return $n1 < $n2 ? ( $n1 > ( $n2 - 0x80000000 ) ) : ( $n2 < ( $n1 - 0x80000000 ) );
}


my $y1998 = timegm( 0, 0, 0, 1, 0, 1998 );
my $y2026 = timegm( 0, 0, 0, 1, 0, 2026 );
my $y2082 = $y2026 << 1;
my $y2054 = $y2082 - $y1998;
my $m2026 = int( 0x80000000 - $y2026 );
my $m2054 = int( 0x80000000 - $y2054 );
my $t2082 = int( $y2082 & 0x7FFFFFFF );
my $t2100 = 1960058752;

sub _string2time {			## parse time specification string
	my $arg = shift;
	return int($arg) if length($arg) < 12;
	my ( $y, $m, @dhms ) = unpack 'a4 a2 a2 a2 a2 a2', $arg . '00';
	if ( $arg lt '20380119031408' ) {			# calendar folding
		return timegm( reverse(@dhms), $m - 1, $y ) if $y < 2026;
		return timegm( reverse(@dhms), $m - 1, $y - 56 ) + $y2026;
	} elsif ( $y > 2082 ) {
		my $z = timegm( reverse(@dhms), $m - 1, $y - 84 );    # expunge 29 Feb 2100
		return $z < 1456790400 ? $z + $y2054 : $z + $y2054 - 86400;
	}
	return ( timegm( reverse(@dhms), $m - 1, $y - 56 ) + $y2054 ) - $y1998;
}


sub _time2string {			## format time specification string
	my $arg	 = shift;
	my $ls31 = int( $arg & 0x7FFFFFFF );
	if ( $arg & 0x80000000 ) {

		if ( $ls31 > $t2082 ) {
			$ls31 += 86400 unless $ls31 < $t2100;	# expunge 29 Feb 2100
			my ( $yy, $mm, @dhms ) = reverse( ( gmtime( $ls31 + $m2054 ) )[0 .. 5] );
			return sprintf '%d%02d%02d%02d%02d%02d', $yy + 1984, $mm + 1, @dhms;
		}

		my ( $yy, $mm, @dhms ) = reverse( ( gmtime( $ls31 + $m2026 ) )[0 .. 5] );
		return sprintf '%d%02d%02d%02d%02d%02d', $yy + 1956, $mm + 1, @dhms;


	} elsif ( $ls31 > $y2026 ) {
		my ( $yy, $mm, @dhms ) = reverse( ( gmtime( $ls31 - $y2026 ) )[0 .. 5] );
		return sprintf '%d%02d%02d%02d%02d%02d', $yy + 1956, $mm + 1, @dhms;
	}

	my ( $yy, $mm, @dhms ) = reverse( ( gmtime $ls31 )[0 .. 5] );
	return sprintf '%d%02d%02d%02d%02d%02d', $yy + 1900, $mm + 1, @dhms;
}

########################################


1;
__END__


=head1 SYNOPSIS

	use Net::DNS;
	$rr = Net::DNS::RR->new('name SIG typecovered algorithm labels
				orgttl sigexpiration siginception
				keytag signame signature');

	use Net::DNS::SEC;
	$sigrr = Net::DNS::RR::SIG->create(
				$string, $keypath,
				sigval => 10	# minutes
				);

	$sigrr->verify( $string, $keyrr ) || die $sigrr->vrfyerrstr;
	$sigrr->verify( $packet, $keyrr ) || die $sigrr->vrfyerrstr;

=head1 DESCRIPTION

Class for DNS digital signature (SIG) resource records.

In addition to the regular methods inherited from Net::DNS::RR the
class contains a method to sign packets and scalar data strings
using private keys (create) and a method for verifying signatures.

The SIG RR is an implementation of RFC2931. 
See L<Net::DNS::RR::RRSIG> for an implementation of RFC4034.

=head1 METHODS

The available methods are those inherited from the base class augmented
by the type-specific methods defined in this package.

Use of undocumented package features or direct access to internal data
structures is discouraged and could result in program termination or
other unpredictable behaviour.


=head2 algorithm

	$algorithm = $rr->algorithm;

The algorithm number field identifies the cryptographic algorithm
used to create the signature.

algorithm() may also be invoked as a class method or simple function
to perform mnemonic and numeric code translation.

=head2 sigexpiration and siginception times

=head2 sigex sigin sigval

	$expiration = $rr->sigexpiration;
	$expiration = $rr->sigexpiration( $value );

	$inception = $rr->siginception;
	$inception = $rr->siginception( $value );

The signature expiration and inception fields specify a validity
time interval for the signature.

The value may be specified by a string with format 'yyyymmddhhmmss'
or a Perl time() value.

Return values are dual-valued, providing either a string value or
numerical Perl time() value.

=head2 keytag

	$keytag = $rr->keytag;
	$rr->keytag( $keytag );

The keytag field contains the key tag value of the KEY RR that
validates this signature.

=head2 signame

	$signame = $rr->signame;
	$rr->signame( $signame );

The signer name field value identifies the owner name of the KEY
RR that a validator is supposed to use to validate this signature.

=head2 signature

=head2 sig

	$sig = $rr->sig;
	$rr->sig( $sig );

The Signature field contains the cryptographic signature that covers
the SIG RDATA (excluding the Signature field) and the subject data.

=head2 sigbin

	$sigbin = $rr->sigbin;
	$rr->sigbin( $sigbin );

Binary representation of the cryptographic signature.

=head2 create

Create a signature over scalar data.

	use Net::DNS::SEC;

	$keypath = '/home/olaf/keys/Kbla.foo.+001+60114.private';

	$sigrr = Net::DNS::RR::SIG->create( $data, $keypath );

	$sigrr = Net::DNS::RR::SIG->create(
				$data, $keypath,
				sigval => 10
				);
	$sigrr->print;


	# Alternatively use Net::DNS::SEC::Private 

	$private = Net::DNS::SEC::Private->new($keypath);

	$sigrr= Net::DNS::RR::SIG->create( $data, $private );


create() is an alternative constructor for a SIG RR object.  

This method returns a SIG with the signature over the data made with
the private key stored in the key file.

The first argument is a scalar that contains the data to be signed.

The second argument is a string which specifies the path to a file
containing the private key as generated using dnssec-keygen, a program
that comes with the ISC BIND distribution.

The optional remaining arguments consist of ( name => value ) pairs
as follows:

	sigin  => 20241201010101,	# signature inception
	sigex  => 20241201011101,	# signature expiration
	sigval => 10,			# validity window (minutes)

The sigin and sigex values may be specified as Perl time values or as
a string with the format 'yyyymmddhhmmss'. The default for sigin is
the time of signing. 

The sigval argument specifies the signature validity window in minutes
( sigex = sigin + sigval ).

By default the signature is valid for 10 minutes.

=head2 verify

	$verify = $sigrr->verify( $data, $keyrr );
	$verify = $sigrr->verify( $data, [$keyrr, $keyrr2, $keyrr3] );

The verify() method performs SIG0 verification of the specified data
against the signature contained in the $sigrr object itself using
the public key in $keyrr.

If a reference to a Net::DNS::Packet is supplied, the method performs
a SIG0 verification on the packet data.

The second argument can either be a Net::DNS::RR::KEYRR object or a
reference to an array of such objects. Verification will return
successful as soon as one of the keys in the array leads to positive
validation.

Returns false on error and sets $sig->vrfyerrstr

=head2 vrfyerrstr

	$sig0 = $packet->sigrr || die 'not signed';
	print $sig0->vrfyerrstr unless $sig0->verify( $packet, $keyrr );

	$sigrr->verify( $packet, $keyrr ) || die $sigrr->vrfyerrstr;

=head1 KEY GENERATION

Private key files and corresponding public DNSKEY records
are most conveniently generated using dnssec-keygen,
a program that comes with the ISC BIND distribution.

	dnssec-keygen -a 10 -b 2048 rsa.example.

	dnssec-keygen -a 13 -f ksk  ecdsa.example.
	dnssec-keygen -a 13	    ecdsa.example.

Do not change the name of the private key file.
The create method uses the filename as generated by dnssec-keygen
to determine the keyowner, algorithm, and the keyid (keytag).


=head1 REMARKS

The code is not optimised for speed.

If this code is still around in 2100 (not a leap year) you will
need to check for proper handling of times after 28th February.

=head1 ACKNOWLEDGMENTS

Although their original code may have disappeared following redesign of
Net::DNS, Net::DNS::SEC and the OpenSSL API, the following individual
contributors deserve to be recognised for their significant influence
on the development of the SIG package.

Andy Vaskys (Network Associates Laboratories) supplied code for RSA.

T.J. Mather provided support for the DSA algorithm.


=head1 COPYRIGHT

Copyright (c)2001-2005 RIPE NCC,   Olaf M. Kolkman

Copyright (c)2007-2008 NLnet Labs, Olaf M. Kolkman

Portions Copyright (c)2014 Dick Franks

All rights reserved.

Package template (c)2009,2012 O.M.Kolkman and R.W.Franks.


=head1 LICENSE

Permission to use, copy, modify, and distribute this software and its
documentation for any purpose and without fee is hereby granted, provided
that the original copyright notices appear in all copies and that both
copyright notice and this permission notice appear in supporting
documentation, and that the name of the author not be used in advertising
or publicity pertaining to distribution of the software without specific
prior written permission.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.


=head1 SEE ALSO

L<perl> L<Net::DNS> L<Net::DNS::RR>
L<Net::DNS::SEC>
L<RFC2535(4)|https://iana.org/go/rfc2535#section-4>
L<RFC2936|https://iana.org/go/rfc2936>
L<RFC2931|https://iana.org/go/rfc2931>
L<RFC3110|https://iana.org/go/rfc3110>
L<RFC4034|https://iana.org/go/rfc4034>

L<Algorithm Numbers|https://iana.org/assignments/dns-sec-alg-numbers>

L<BIND Administrator Reference Manual|https://bind9.readthedocs.io/en/latest/>

=cut
