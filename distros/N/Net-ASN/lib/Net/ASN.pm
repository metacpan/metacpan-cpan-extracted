#    ASN.pm - Perl module to manipulate autonomous system numbers
#
#    Author: David J. Freedman <lochii AT convergence DOT cx>
#
#    Copyright (C) 2008 Convergence Inc.
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms as perl itself.
#

package Net::ASN;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

BEGIN {

	require Exporter;

	@ISA = qw(Exporter);

	@EXPORT = qw();

	%EXPORT_TAGS = (
                    all => [qw{ 
				plaintodot	plaintodotplus
				dottodotplus	dottoplain
				dottoplain16	dotplustodot
				dotplustoplain	dotplustoplain16
				isprivateasn
                                } ],
                   );

	@EXPORT_OK = qw();

	Exporter::export_ok_tags('all');

    	$VERSION = '1.07';
}

# Preloaded methods go here.
use Carp;

#Constants
use constant	AS_TRANS => 23456;
use constant	AS16_START 	   => 1;
use constant	AS16_PRIVATE_START => 64512;
use constant	AS16_PRIVATE_END   => 65534;
use constant	AS16_END	   => 65535;
use constant	AS32_START 	   => 65536;
use constant	AS32_PRIVATE_START => 4200000000;
use constant	AS32_PRIVATE_END   => 4294967294;
use constant	AS32_END 	   => 4294967295;

##OO Methods

#Initialise with an ASN
#
sub new {

	my $class 	= shift;
	my $self	= {};

	my $asn		= shift;

	my $asasdot	= shift;

	bless $self, $class;

	$self->_parseasn($asn,$asasdot);	#Parse the ASN

	return $self;		

}

#Parses an ASN, in any format
sub _parseasn ($;$) {

	my $self = shift;
	my $inasn = shift;
	my $asasdot = shift;

	#Perform some basic checks
	#
	#1) did we even get a parameter?
	unless ($inasn) {
		croak __PACKAGE__, ": ASN not provided";
	}
	#2) does the ASN contain a valid character set?
	unless ($inasn=~m/^[\d\.]+$/) {
		croak __PACKAGE__, ": Invalid ASN (Illegal Characters)";
	}
	#3) Next, check the format

	if ($inasn=~m/^(\d+)$/) {		#ASN is ASN16 (1-65535) or ASN32 ASPLAIN (1-4294967295) or ASDOT if forced
		if ($asasdot) {
			if ($inasn >= AS16_START && $inasn <=  AS16_END) {
				$self->{_informat} = 'asdot';
				$self->{_asdot} = $inasn;
			}
			else {
				croak __PACKAGE__, ": Invalid ASDOT ASN (ASDOT does NOT permit ASPLAIN notation for ASNs 63356-4294967295)";
			}
		}
		elsif ($inasn >= AS16_START && $inasn <=  AS16_END) {
			$self->{_informat} = 'asplain16';
			$self->{_asplain16} = $inasn;
		}
		elsif ($inasn >= AS32_START && $inasn <= AS32_END) {
			$self->{_informat} = 'asplain32';
			$self->{_asplain32} = $inasn;
		}
		else {
			croak __PACKAGE__, ": Invalid ASPLAIN ASN (must be between 1-4294967295)";
		}
	}
	elsif ($inasn=~m/^(\d+)\.(\d+)$/) {	#ASN is ASN32 ASDOT+ notation or ASDOT if forced

		my $firstasn = $1;
		my $secondasn = $2;

		unless (
			($firstasn >= 0 && $firstasn <= AS16_END) && 
			($secondasn >= 0 && $secondasn <= AS16_END) &&
			(
				($firstasn  > 0) ||
				($secondasn > 0)
			)
		) {
			croak __PACKAGE__, ": Invalid ASDOT(+) ASN (must be between 0-65535.0-65535 and NOT 0.0)";
		}

		#Allow input as ASDOT if $asasdot is populated
		if ($asasdot) {
			if ($firstasn > 0) {
				$self->{_informat} = 'asdot';
			}
			else {
				croak __PACKAGE__, ": Invalid ASDOT ASN (ASDOT does NOT permit ASDOT+ notation for ASNs 0-65535)";
			}
		}
		else {
			$self->{_informat} = 'asdotplus';
		}
		$self->{_asdotsedtet1} = $firstasn;
		$self->{_asdotsedtet2} = $secondasn;

	}
	else {
		croak __PACKAGE__, ": Invalid ASN (Illegal Format)";
	}

	return;

}

sub _plaintodot ($) {
		
	my $self = shift;
	my $asplain = shift;

        unless ($asplain=~m/^(\d+)$/) {
		die ("Internal Error: _plaintodot called with invalid plain");
        }
        else {
                my $asdot=int($asplain/65536);
                $asdot .= ".";
                $asdot .= ($asplain - ($asdot*65536));
                return $asdot;
        }

}

sub _dottoplain ($) {

	my $self = shift;
	my $asdot = shift;

        unless ($asdot=~m/^(\d+)\.(\d+)$/) {
		die("Internal Error: _dottoplain called with invalid dot");
        }
        else {
                my $asplain1 = $1;
                my $asplain2 = $2;
                my $asplain = (65536 * $asplain1);
                $asplain+=$asplain2;
                return $asplain;
        }
}

##Produce ASDOT representation of parsed ASN
sub toasdot () {

	my $self = shift;
	if ($self->{_informat} eq 'asdot') {		#User wants asdot and we already have it, just return it
		if ($self->{_asdot}) {
			return $self->{_asdot};
		}
		else {
			my $value = "$self->{_asdotsedtet1}.$self->{_asdotsedtet2}";
			return ($value);
		}

	}
	elsif ($self->{_informat} eq 'asdotplus') {	#User wants asdot and has given us asdotplus, so return asplain if 
		if ($self->{_asdotsedtet1} == 0) {	#If first sedtet is 0, return the second only
			return ($self->{_asdotsedtet2});
		}
		else {					#Else, return both
			my $value = "$self->{_asdotsedtet1}.$self->{_asdotsedtet2}";
			return ($value);
		}
	}
	elsif ($self->{_informat} eq 'asplain16') {	#User wants asdot and has given us an 16 bit asplain (just return asplain)
		my $value = $self->{_asplain16};
		return ($value);
	}
	elsif ($self->{_informat} eq 'asplain32') {	#User wants asdot and has given us an 32 bit asplain
		my $value = $self->{_asplain32};
		$value = $self->_plaintodot($value);
		return ($value);
	}
	else {
		die ("Internal Error: no acceptable informat defined");
	}

}

##Produce ASDOT+ representation of parsed ASN
sub toasdotplus () {

        my $self = shift;
	if ($self->{_informat} eq 'asdot') {		#User wants asdotplus and we have asdot
		if ($self->{_asdot}) {
			my $value = $self->_plaintodot($self->{_asdot});
			return ($value);
		}
		else {
			my $value = "$self->{_asdotsedtet1}.$self->{_asdotsedtet2}";
			return ($value);
		}
	}
        elsif ($self->{_informat} eq 'asdotplus') {     #User wants asdotplus and we have it, just return it
                my $value = "$self->{_asdotsedtet1}.$self->{_asdotsedtet2}";
                return ($value);
        }
        elsif ($self->{_informat} eq 'asplain16') {     #User wants asdotplus and has given us an 16 bit asplain
		my $value = $self->{_asplain16};
		$value = $self->_plaintodot($value);
		return ($value);
        }
        elsif ($self->{_informat} eq 'asplain32') {     #User wants asdotplus and has given us an 32 bit asplain
                my $value = $self->{_asplain32};
                $value = $self->_plaintodot($value);
                return ($value);
        }
        else {
                die ("Internal Error: no acceptable informat defined");
        }

}

##Produce ASPLAIN representation of parsed ASN (32 bit version)
sub toasplain () {

	my $self = shift;

	if ($self->{_informat} eq 'asdot') {		#User wants asplain and we have asdot
		if ($self->{_asdot}) {
			return ($self->{_asdot});
		}
		else {
			my $value = "$self->{_asdotsedtet1}.$self->{_asdotsedtet2}";
			$value = $self->_dottoplain($value);
			return ($value);
		}	
	}
	elsif ($self->{_informat} eq 'asplain16') {	#User wants asplain and we have it
		my $value = $self->{_asplain16};
		return ($value);
	}
	elsif ($self->{_informat} eq 'asplain32') {	#User wants asplain and we have it
		my $value = $self->{_asplain32};
		return ($value);
	}
	elsif ($self->{_informat} eq 'asdotplus') {	#User wants asplain and has given us asdotplus so return asplain
		my $value = "$self->{_asdotsedtet1}.$self->{_asdotsedtet2}";
		$value = $self->_dottoplain($value);
		return ($value);
	}
        else {
                die ("Internal Error: no acceptable informat defined");
        }
}

##Produce ASPLAIN representation of parsed ASN (16 bit version)
sub toasplain16 () {

        my $self = shift;

	if ($self->{_informat} eq 'asdot') {		#User wants asplain16 and we have asdot
		if ($self->{_asdot}) {
			return ($self->{_asdot});
		}
		else {
			return (AS_TRANS);
		}	
	}
        elsif ($self->{_informat} eq 'asplain16') {     #User wants asplain and we have it
                my $value = $self->{_asplain16};
                return ($value);
        }
        elsif ($self->{_informat} eq 'asplain32') {     #User wants asplain so return AS_TRANS
                return (AS_TRANS);
        }
        elsif ($self->{_informat} eq 'asdotplus') {     #User wants asplain and has given us asdotplus, return AS_TRANS for 32 bit
		if ($self->{_asdotsedtet1} == 0) {
			return ($self->{_asdotsedtet2});
		}
		else {
			return (AS_TRANS);
		}
        }
        else {
                die ("Internal Error: no acceptable informat defined");
        }
}

##Return parsed type
sub gettype () {
	my $self = shift;
	my $informat = $self->{_informat};
	$informat=~s/\d+//g;	#Remove ASPLAIN differentiation
	return ($informat);
}

##RFC 6996 reserves some ASN's for private use
sub isprivate {
    my $self = shift;
    my $asn = $self->toasplain;
    if ( ( $asn >= AS16_PRIVATE_START && $asn <= AS16_PRIVATE_END ) ||
         ( $asn >= AS32_PRIVATE_START && $asn <= AS32_PRIVATE_END ) ) {
         return 1;
     }
     return 0;
 }

###NON OO Function wrappers
##toasdot
sub plaintodot ($) {
	my $inasn = shift;
	croak __PACKAGE__, ": No ASN specified" unless ($inasn);
	croak __PACKAGE__, ": Must provide ASPLAIN" unless ($inasn=~m/^(\d+)$/);	#Ensure only numerical is passed
	my $asn = Net::ASN->new($inasn) || croak __PACKAGE__, ": Could not create new Net::ASN object";
	return ($asn->toasdot);
}
##toasdotplus
sub plaintodotplus ($) {
        my $inasn = shift;
        croak __PACKAGE__, ": No ASN specified" unless ($inasn);
	croak __PACKAGE__, ": Must provide ASPLAIN" unless ($inasn=~m/^(\d+)$/);	#Ensure only numerical is passed
        my $asn = Net::ASN->new($inasn) || croak __PACKAGE__, ": Could not create new Net::ASN object";
        return ($asn->toasdotplus);
}
##toasdotplus
sub dottodotplus ($) {
        my $inasn = shift;
        croak __PACKAGE__, ": No ASN specified" unless ($inasn);
        my $asn = Net::ASN->new($inasn,1) || croak __PACKAGE__, ": Could not create new Net::ASN object";
        return ($asn->toasdotplus);
}
##toasplain
sub dottoplain ($) {
	my $inasn = shift;
	croak __PACKAGE__, ": No ASN specified" unless ($inasn);
	my $asn = Net::ASN->new($inasn,1) || croak __PACKAGE__, ": Could not create new Net::ASN object";
	return ($asn->toasplain);
}
##toasplain16
sub dottoplain16 ($) {
	my $inasn = shift;
	croak __PACKAGE__, ": No ASN specified" unless ($inasn);
	my $asn = Net::ASN->new($inasn,1) || croak __PACKAGE__, ": Could not create new Net::ASN object";
	return ($asn->toasplain16);
}
##toasdot again
sub dotplustodot ($) {
	my $inasn = shift;
	croak __PACKAGE__, ": No ASN specified" unless ($inasn);
	croak __PACKAGE__, ": Must provide ASDOT+" unless ($inasn=~m/\./);	#Ensure only dotted is passed
	my $asn = Net::ASN->new($inasn) || croak __PACKAGE__, ": Could not create new Net::ASN object";
	return ($asn->toasdot);
}
##toasplain
sub dotplustoplain ($) {
	my $inasn = shift;
	croak __PACKAGE__, ": No ASN specified" unless ($inasn);
	croak __PACKAGE__, ": Must provide ASDOT+" unless ($inasn=~m/\./);	#Ensure only dotted is passed
	my $asn = Net::ASN->new($inasn) || croak __PACKAGE__, ": Could not create new Net::ASN object";
	return ($asn->toasplain);
}
##toasplain16
sub dotplustoplain16 ($) {
	my $inasn = shift;
	croak __PACKAGE__, ": No ASN specified" unless ($inasn);
	croak __PACKAGE__, ": Must provide ASDOT+" unless ($inasn=~m/\./);	#Ensure only dotted is passed
	my $asn = Net::ASN->new($inasn) || croak __PACKAGE__, ": Could not create new Net::ASN object";
	return ($asn->toasplain16);
}

##isprivate
sub isprivateasn ($) {
	my $inasn = shift;
	croak __PACKAGE__, ": No ASN specified" unless ($inasn);
	my $asn = Net::ASN->new($inasn) || croak __PACKAGE__, ": Could not create new Net::ASN object";
	return ($asn->isprivate);
}

1;
__END__
=pod

=head1 NAME

Net::ASN - Perl extension for manipulating autonomous system numbers

=head1 SYNOPSIS

	##OO implementation (methods)

	use Net::ASN;

	my $asn = Net::ASN->new($ARGV[0]);

	print "type     : " . $asn->gettype     . "\n";
	print "asplain16: " . $asn->toasplain16 . "\n";
	print "asplain32: " . $asn->toasplain   . "\n";
	print "asdot    : " . $asn->toasdot     . "\n";
	print "asdotplus: " . $asn->toasdotplus . "\n";
	print "\n";

	##Non OO implementation (functions)
	
	use Net::ASN qw(:all);
	
	my $asplain = 12345;

	print "ASN in asdotplus format is " . plaintodotplus($asplain) . "\n";

	my $asdotplus = '1.1';

	print "ASN in asplain format is "   . dotplustoplain($asdotplus) . "\n";


=head1 DESCRIPTION

Net::ASN provides functions for parsing autonomous system numbers 
(ASNs) as defined in RFC 1771 and extended by RFC4893, also 
converting between formats discussed in RFC5396.

Both an OO implementation (method based) and non-OO (function based)
are provided for convenience.

=head1 METHODS

=over

=item new

	my $asn = Net::ASN->new(1234);		#Automatic parsing
	or
	my $asn = Net::ASN->new(1234,1);	#Parse as ASDOT

Creates a new Net::ASN object, prompting parsing of the supplied parameter, an ASN.
Currently, only ASPLAIN and ASDOT+ are automatically recognised as input formats.
If you wish to force input as ASDOT you must provide a second argument to the constructor.

=item gettype

	my $type = $asn->gettype;

Returns the type of ASN the parser assumes it is dealing with.

=item toasplain

	my $asplain = $asn->toasplain;

Returns the ASPLAIN representation of the parsed ASN

=item toasplain16

        my $asplain = $asn->toasplain16;

Returns the ASPLAIN representation of the parsed ASN if the ASPLAIN
representation is is less than or equal to 65535, else returns AS_TRANS

Use for compabability with 16 bit ASN systems.

=item toasdot

	my $asdot = $asn->toasdot;

Returns the ASDOT representation of the parsed ASN.
If the parsed ASN is ASPLAIN and less than or equal to 65535 then
returns the ASPLAIN

=item toasdotplus

	my $asdotplus = $asn->toasdotplus;

Returns the ASDOT+ representation of the parsed ASN.

=item isprivate

	my $isprivate = $asn->isprivate;

Returns 1 if the number falls within the private reserved ranges according to
RFC6996, 0 otherwise. Will accept any format that L<Net::ASN> can convert to
ASPLAIN 

=back


=head1 FUNCTIONS

=over

=item plaintodot

	my $asdot = plaintodot($asn);

Returns the ASDOT representation of the ASN ($asn)
If $asn is ASPLAIN and less than or equal to 65535 then
returns the ASPLAIN
(Assumes your ASN is in ASPLAIN format)

=item plaintodotplus

	my $asdotplus = plaintodotplus($asn);

Returns the ASDOT+ representation of the ASN ($asn)
(Assumes your ASN is in ASPLAIN format)

=item dottodotplus

        my $asplain = dottodotplus($asn);

Returns the ASDOT+ representation of the ASN ($asn)
(Assumes your ASN is in ASDOT format)

=item dottoplain

        my $asplain = dottoplain($asn);

Returns the ASPLAIN representation of the ASN ($asn)
(Assumes your ASN is in ASDOT format)

=item dottoplain16

        my $asplain = dottoplain16($asn);

Returns the ASPLAIN representation of the ASN ($asn) if the ASPLAIN
representation is is less than or equal to 65535, else returns AS_TRANS
(Assumes your ASN is in ASDOT format)

=item dotplustodot

	my $asdot = dotplustodot($asn);

Returns the ASDOT representation of the ASN ($asn)
(Assumes your ASN is in ASDOT+ format)

=item dotplustoplain

	my $asplain = dotplustoplain($asn);

Returns the ASPLAIN representation of the ASN ($asn)
(Assumes your ASN is in ASDOT+ format)

=item dotplustoplain16

	my $asplain = dotplustoplain16($asn);

Returns the ASPLAIN representation of the ASN ($asn) if the ASPLAIN
representation is is less than or equal to 65535, else returns AS_TRANS
(Assumes your ASN is in ASDOT+ format)

=item isprivateasn

	my $isprivateasn = isprivateasn($asn);

Returns 1 if the number falls within the private reserved ranges according to
RFC6996, 0 otherwise. Will accept any format that L<Net::ASN> can convert to
ASPLAIN 

=back

=head1 AUTHOR

David J. Freedman <lochii AT convergence DOT cx>

=head1 COPYRIGHT

Copyright (c) 2008 Convergence Inc.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms as perl itself.

=head1 SEE ALSO

=head1 REPOSITORY

L<https://github.com/lochiiconnectivity/netasn.git

perl(1)

=cut

