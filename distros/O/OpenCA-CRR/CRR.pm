## OpenCA::CRR
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
package OpenCA::CRR;

$VERSION = '0.0.2';

my %params = {
	crr => undef,
	parsedCRR => undef,
	signature => undef,
	body => undef,
};

sub new {
	my $that = shift;
	my $class = ref($that) || $that;
	
	my $self = {
		%params,
	};

	bless $self, $class;

	my $keys = { @_ };

	$self->{crr} = $keys->{DATA} || $_[0];
	$self->{parsedCRR} = $self->getParsed( $self->{crr} );

	return if ( (not $self->{crr}) or (not $self->{parsedCRR}) );

	$self->{signature} = $self->{parsedCRR}->{SIGNATURE};
	$self->{body} = $self->{parsedCRR}->{BODY};

	return $self;
}
sub parseCRR {
	my $self = shift;
	my @keys = @_;

	my $crr = $keys[0];
	my $beginCRR = "-----BEGIN CRR-----";
	my $endCRR   = "-----END CRR-----";
	my $beginSig = "-----BEGIN PKCS7-----";
	my $endSig   = "-----END PKCS7-----";

	my $line, $dn, $serial, $notBefore, $notAfter, $issuer;
	my $signature = "";
	my $body = "";
	my $isSignature = 0;
	my $isCRR = 0;

	return if (not $crr);

	my @lines = split ( /\n/, $crr );
	foreach $line ( @lines ) {
		$isCRR = 1 if( $line =~ /$beginCRR/ );
		$isCRR = 0 if( $line =~ /$endCRR/ );

		$isSignature = 1 if( $line =~ /$beginSig/ );
		$isSignature = 0 if( $line =~ /$endSig/ );

		if( $isCRR ) {
			$body .= "$line\n";

			if ($line =~ /Submitted on:/) {
				( $date ) =
					( $line =~ /Submitted on:[\s]*(.*)/i );
			}

			if ($line =~ /DN:/) {
				( $dn ) = ( $line =~ /DN:[\s]*(.*)/ );
			}

                	if ($line =~ /Issued by:/) {
                    		($issuer) =
					( $line=~ /Issued by:[\s]*(.*)/i );
                	};

                	if ($line =~ /Not After[\s]*:/) {
                    		($notAfter) =
					($line =~ /Not After:[\s]*(.*)/i );
                	};
                	if ($line =~ /Not Before:/) {
                        	($notBefore) =
					( $line=~ /Not Before:[\s]*(.*)/i );
                	};

                	if ($line =~ /Serial:/) {
                        	($serial) =
					( $line =~ /Serial:[\s]*([0-9A-F]+)/i);

				if( length( $serial ) % 2 ) {
					$serial = "0" . $serial;
				}
                	}

		} elsif ( $isSignature ) {
			$signature .= "$line\n";
		}
	}

	my $ret = {
		    SUBMIT_DATE => $date,
		    BODY => $body,
		    SIGNATURE => $signature,
                    CERTIFICATE_DN => $dn,
                    CERTIFICATE_NOT_BEFORE => $notbefore,
                    CERTIFICATE_NOT_AFTER => $notafter,
                    CERTIFICATE_SERIAL => $serial,
                    CERTIFICATE_ISSUER => $issuer,
        };

	return $ret;
}

sub getParsed {
	my $self = shift;

	return if ( not $self->{parsedCRR} );
	return $self->{parsedCRR};
}

sub getSignature {
	my $self = shift;

	return if ( not $self->{signature} );
	return $self->{signature};
}

sub getBody {
	my $self = shift;

	return if ( not $self->{body} );
	return $self->{body};
}

sub getCRR {
	my $self = shift;

	return if ( not $self->{crr} );
	return $self->{crr};
}


1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

OpenCA::CRR - Perl extention to handle CRR objects.

=head1 SYNOPSIS

  use OpenCA::CRR;

=head1 DESCRIPTION

This class handles CRR (Certificate Revoking Request) objects. Them can
be signed or not depending on the implementation. CRR objects begin and
end with boundaries:

	-----BEGIN CRR-----
	-----END CRR-----

Currently implemented functions are:

	new          - Creates a new instance of the class.
	getParsed    - Returns a parsed version of the object.
	getSignature - Returns the signature (if present).
	getBody      - Get Signed Text (boundaries included).
	getCRR	     - Returns passed CRR (sig. incl.).

=head1 FUNCTIONS

=head2 sub new () - Creates a new instance of the class.

	This function creates a new instance of the class. You have
	to provide a valid CRR data as argument.

	EXAMPLE:

		my $CRR = new OpenCA::CRR( $crrData );

=head2 sub getParsed () - Returns a parsed CRR.

	This function returns a parsed CRR as an HASH object. The
	returned object has the following structure:

		my $ret = {
		    SUBMIT_DATE => $date,
		    BODY => $body,
		    SIGNATURE => $signature,
                    CERTIFICATE_DN => $dn,
                    CERTIFICATE_NOT_BEFORE => $notbefore,
                    CERTIFICATE_NOT_AFTER => $notafter,
                    CERTIFICATE_SERIAL => $serial,
                    CERTIFICATE_ISSUER => $issuer,
        	};

=head2 sub getSignature() - Returns signature.

	Use this function to retrieve the signature. Remember the
	signature is intended to be PKCS7 and returned value includes
	boundaries.

	EXAMPLE:

		print $CRR->getSignature();



			
=head1 AUTHOR

Massimiliano Pala <madwolf@openca.org>

=head1 SEE ALSO

perl(1).

=cut
