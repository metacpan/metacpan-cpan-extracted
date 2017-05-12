## OpenCA::CRL
##
## Copyright (C) 1998-1999 Massimiliano Pala (madwolf@openca.org)
## All rights reserved.
##
## This library is free for commercial and non-commercial use as long as
## the following conditions are aheared to.  The following conditions
## apply to all code found in this distribution, be it the RC4, RSA,
## lhash, DES, etc., code; not just the SSL code.  The documentation
## included with this distribution is covered by the same copyright terms
## 
## Copyright remains Massimiliano Pala's, and as such any Copyright notices
## in the code are not to be removed.
## If this package is used in a product, Massimiliano Pala should be given
## attribution as the author of the parts of the library used.
## This can be in the form of a textual message at program startup or
## in documentation (online or textual) provided with the package.
## 
## Redistribution and use in source and binary forms, with or without
## modification, are permitted provided that the following conditions
## are met:
## 1. Redistributions of source code must retain the copyright
##    notice, this list of conditions and the following disclaimer.
## 2. Redistributions in binary form must reproduce the above copyright
##    notice, this list of conditions and the following disclaimer in the
##    documentation and/or other materials provided with the distribution.
## 3. All advertising materials mentioning features or use of this software
##    must display the following acknowledgement:
##    "This product includes OpenCA software written by Massimiliano Pala
##     (madwolf@openca.org) and the OpenCA Group (www.openca.org)"
## 4. If you include any Windows specific code (or a derivative thereof) from 
##    some directory (application code) you must include an acknowledgement:
##    "This product includes OpenCA software (www.openca.org)"
## 
## THIS SOFTWARE IS PROVIDED BY OPENCA DEVELOPERS ``AS IS'' AND
## ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
## IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
## ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
## FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
## DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
## OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
## HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
## LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
## OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
## SUCH DAMAGE.
## 
## The licence and distribution terms for any publically available version or
## derivative of this code cannot be changed.  i.e. this code cannot simply be
## copied and put under another distribution licence
## [including the GNU Public Licence.]
##

## the module's errorcode is 76
##
## functions:
##
## new		11
## init		12
## parseCRL	13
## getHeader	21
## getBody	22
## getTXT	31
## getParsed	41
## getPEM	32
## getDER	33
## getItem	51
## getSerial	52
## setParams    61

use strict;

package OpenCA::CRL;

our ($errno, $errval);

($OpenCA::CRL::VERSION = '$Revision: 1.17 $' )=~ s/(?:^.*: (\d+))|(?:\s+\$$)/defined $1?"0\.9":""/eg;

my %params = (
	crl => undef, 
	item => undef,
	pwd => undef, 
	crlFormat => undef,
	pemCRL => undef,
	derCRL => undef,
	txtCRL => undef,
	parsedItem => undef,
	backend => undef,
	beginHeader => undef,
	endHeader => undef
);

sub setError {
	my $self = shift;

	if (scalar (@_) == 4) {
		my $keys = { @_ };
		$errval = $keys->{ERRVAL};
		$errno  = $keys->{ERRNO};
	} else {
		$errno  = $_[0];
		$errval = $_[1];
	}

	## support for: return $self->setError (1234, "Something fails.") if (not $xyz);
	return undef;
}

sub new {
	my $that = shift;
	my $class = ref($that) || $that;

        my $self = {
		%params,
	};

        bless $self, $class;

        my $keys = { @_ };

        $self->{crl}       = $keys->{DATA};
        $self->{pwd}       = $keys->{PASSWD};
        $self->{crlFormat} = ( $keys->{FORMAT} or $keys->{INFORM} or "PEM");
        $self->{backend}   = $keys->{SHELL};

	return $self->setError (7611011, "OpenCA::CRL->new: There is no crypto-backend specified.")
		if( not $self->{backend} );

	my $infile = $keys->{INFILE};
	my $cakey  = $keys->{CAKEY};
	my $cacert = $keys->{CACERT};
	my $days   = $keys->{DAYS};
	my $exts   = $keys->{EXTS};

	$self->{beginHeader} = "-----BEGIN HEADER-----";
	$self->{endHeader} = "-----END HEADER-----";

	if (defined($infile) and ($infile ne "") ) {
		my $tmpLine;
		open( FD, "<$infile" ) 
			or return $self->setError (7611021, "OpenCA::CRL->new: Cannot open infile $infile for reading.");
		while( $tmpLine = <FD> ) {
			$self->{crl} .= $tmpLine;
		}
		close(FD);
        }

	if (not $self->{crl})
	{
	# the can be stored directly in the token ({backend})
	#
	#if( ($cacert) or ($cakey) ) {
	#	return $self->setError (7611031, "OpenCA::CRL->new: You must specify the CA-certificate too ".
	#				"if you want to issue a CRL.")
	#		if (not $cacert);
	#	return $self->setError (7611032, "OpenCA::CRL->new: You must specify the CA's private key too ".
	#				"if you want to issue a CRL.")
	#		if (not $cakey);

		$self->{crl} = $self->{backend}->issueCrl(
		                                          CAKEY      => $cakey,
		                                          USE_ENGINE => 1,
		                                          CACERT     => $cacert,
		                                          OUTFORM    => $self->{crlFormat},
		                                          DAYS       => $days,
		                                          PASSWD     => $self->{pwd},
		                                          EXTS       => $exts,
		                                          NOUNIQUEDN => $keys->{NOUNIQUEDN} );

		return $self->setError (7611035, "OpenCA::CRL->new: Failed to issue a new CRL ".
					"(".$OpenCA::OpenSSL::errno.")\n".$OpenCA::OpenSSL::errval)
			if ( not $self->{crl} );
	}


        if ( $self->{crl} ne "" ) {
		$self->{item} = $self->{crl};

		$self->{crl} = $self->getBody( ITEM=>$self->{item} );

                if ( not $self->init()) {
                        return $self->setError (7611041, "OpenCA::CRL->new: Failed to issue a new CRL ".
						"($errno)\n$errval");
                }

        }

	return $self;
}


sub init {
        my $self = shift;
        my $keys = { @_ };

        return $self->setError (7612011, "OpenCA::CRL->init: There is no CRL present.")
		if (not $self->{crl});

        $self->{pemCRL} = "";

        $self->{derCRL} = "";

        $self->{txtCRL} = "";

        $self->{parsedItem} = $self->parseCRL();
	return $self->setError (7612021, "OpenCA::CRL->init: Cannot parse CRL ($errno)\n$errval")
		if (not $self->{parsedItem});

        return 1;
}

sub parseCRL {

	my $self = shift;
	my $keys = { @_ };

	my ( $version, $issuer, $last, $next, $alg, $tmp);
	my @list;
	my @certs;

	my ( $head, $body );

        my @attList = ( "VERSION", "ISSUER", "NEXTUPDATE", "LASTUPDATE", "SIGNATURE_ALGORITHM", "REVOKED" );

        my $hret = $self->{backend}->getCRLAttribute(
                        ATTRIBUTE_LIST => \@attList,
			DATA           => $self->{crl},
			INFORM         => $self->{crlFormat});
	if (not $hret) {
		return $self->setError (7613015, "OpenCA::CRL->parseCRL: Cryptobackend fails ".
					"(".$OpenCA::OpenSSL::errno.")\n".$OpenCA::OpenSSL::errval);
	}

	## Parse lines ...
	@certs = split ( /\n/i, $hret->{REVOKED} );
	for (my $i=0; $i<scalar @certs; $i++)
	{
		my $serial = $certs[$i++];
		my $date   = $certs[$i];
		my $ext    = "";
		while ($certs[$i+1] =~ /^  /) {
			$ext .= $certs[++$i]."\n";
		}

		my $entry = {
			SERIAL => $serial,
			DATE   => $date }; 

		@list = ( @list, $entry );
	}

	my $ret = {
			VERSION           => $hret->{VERSION},
			ALGORITHM         => $hret->{SIGNATURE_ALGORITHM},
		  	ISSUER            => $hret->{ISSUER},
		  	LAST_UPDATE       => $hret->{LASTUPDATE},
		  	NEXT_UPDATE       => $hret->{NEXTUPDATE},
			BODY              => $self->getBody( ITEM=> $self->{item} ),
			ITEM              => $self->getBody( ITEM=> $self->{item} ),
			HEADER            => $self->getHeader ( ITEM=>$self->{item} ),
		  	LIST              => [ @list ],
			FLAG_EXPORT_STATE => 0
		  };

	return $ret;
}

sub getHeader {
	my $self = shift;
	my $keys = { @_ };
	my $req = $keys->{ITEM};

	my ( $txt, $ret, $i, $key, $val );

	my $beginHeader = $self->{beginHeader};
	my $endHeader = $self->{endHeader};

	if( ($txt) = ( $req =~ /$beginHeader\n([\S\s\n]+)\n$endHeader/m) ) {
		foreach $i ( split ( /\n/, $txt ) ) {
			$i =~ s/\s*=\s*/=/;
			( $key, $val ) = ( $i =~ /(.*)\s*=\s*(.*)\s*/ );
			$ret->{$key} = $val;
		}
	}

	return $ret;
}

sub getBody {
	my $self = shift;
	my $keys = { @_ };

	my $ret = $keys->{ITEM};

	my $beginHeader 	= $self->{beginHeader};
	my $endHeader 		= $self->{endHeader};

	## Let's throw away text between the two headers, included
	$ret =~ s/($beginHeader[\S\s\n]+$endHeader\n)//;

	return $ret;
}

sub getParsed {
	my $self = shift;

	return $self->setError (7641011, "OpenCA::CRL->getParsed: The CRL was not parsed.")
		if ( not $self->{parsedItem} );
	return $self->{parsedItem};
}

sub getPEM {
	my $self = shift;

	if ( $self->{crlFormat} eq 'PEM' ) {
		$self->{crl} =~ s/^\n*//;
		$self->{crl} =~ s/\n*$/\n/;
		return $self->{crl};
	}
	if (not $self->{pemCRL}) {
		$self->{pemCRL} = $self->{backend}->dataConvert( DATA=>$self->{crl},
                                        DATATYPE=>"CRL",
                                        INFORM=>$self->{crlFormat},
                                        OUTFORM=>"PEM" );
		return $self->setError (7632011, "OpenCA::CRL->init: Cannot convert CRL to PEM-format ".
					"(".$OpenCA::OpenSSL::errno.")\n".$OpenCA::OpenSSL::errval)
			if (not $self->{pemCRL});
	}

	return $self->{pemCRL};
}

sub getDER {
	my $self = shift;

	if ( $self->{crlFormat} eq 'DER' ) {
		return $self->{crl};
	}
	if (not $self->{derCRL}) {
		$self->{derCRL} = $self->{backend}->dataConvert( DATA=>$self->{crl},
                                        DATATYPE=>"CRL",
                                        INFORM=>$self->{crlFormat},
                                        OUTFORM=>"DER" );
		return $self->setError (7633011, "OpenCA::CRL->getDER: Cannot convert CRL to DER-format ".
					"(".$OpenCA::OpenSSL::errno.")\n".$OpenCA::OpenSSL::errval)
			if (not $self->{derCRL});
	}

	return $self->{derCRL};
}

sub getTXT {
	my $self = shift;

	if (not $self->{txtCRL}) {
		$self->{txtCRL} = $self->{backend}->dataConvert( DATA=>$self->{crl},
                                        DATATYPE=>"CRL",
                                        INFORM=>$self->{crlFormat},
                                        OUTFORM=>"TXT" );
		return $self->setError (7631011, "OpenCA::CRL->getTXT: Cannot convert CRL to TXT-format ".
				"(".$OpenCA::OpenSSL::errno.")\n".$OpenCA::OpenSSL::errval)
			if (not $self->{txtCRL});
	}

	return $self->{txtCRL};
}

sub getItem {
	my $self = shift;
	my $txtItem;

	$txtItem  = $self->{beginHeader}."\n";
        $txtItem .= $self->getHeader ();
	$txtItem .= $self->{endHeader}."\n";
	$txtItem .= $self->getPEM ();

	return $txtItem;
}

sub getSerial {
	my $self = shift;

	return $self->{backend}->getDigest ( DATA => $self->getPEM() );
}

sub setParams {

	my $self = shift;
	my $params = { @_ };
	my $key;

	foreach $key ( keys %{$params} ) {
		## we should place the parameters here
	}

	return 1;
}

# Below is the stub of documentation for your module. You better edit it!
1;
