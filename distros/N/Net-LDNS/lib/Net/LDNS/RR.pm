package Net::LDNS::RR;

use Net::LDNS::RR::A;
use Net::LDNS::RR::A6;
use Net::LDNS::RR::AAAA;
use Net::LDNS::RR::AFSDB;
use Net::LDNS::RR::APL;
use Net::LDNS::RR::ATMA;
use Net::LDNS::RR::CAA;
use Net::LDNS::RR::CDS;
use Net::LDNS::RR::CERT;
use Net::LDNS::RR::CNAME;
use Net::LDNS::RR::DHCID;
use Net::LDNS::RR::DLV;
use Net::LDNS::RR::DNAME;
use Net::LDNS::RR::DNSKEY;
use Net::LDNS::RR::DS;
use Net::LDNS::RR::EID;
use Net::LDNS::RR::EUI48;
use Net::LDNS::RR::EUI64;
use Net::LDNS::RR::GID;
use Net::LDNS::RR::GPOS;
use Net::LDNS::RR::HINFO;
use Net::LDNS::RR::HIP;
use Net::LDNS::RR::IPSECKEY;
use Net::LDNS::RR::ISDN;
use Net::LDNS::RR::KEY;
use Net::LDNS::RR::KX;
use Net::LDNS::RR::L32;
use Net::LDNS::RR::L64;
use Net::LDNS::RR::LOC;
use Net::LDNS::RR::LP;
use Net::LDNS::RR::MAILA;
use Net::LDNS::RR::MAILB;
use Net::LDNS::RR::MB;
use Net::LDNS::RR::MD;
use Net::LDNS::RR::MF;
use Net::LDNS::RR::MG;
use Net::LDNS::RR::MINFO;
use Net::LDNS::RR::MR;
use Net::LDNS::RR::MX;
use Net::LDNS::RR::NAPTR;
use Net::LDNS::RR::NID;
use Net::LDNS::RR::NIMLOC;
use Net::LDNS::RR::NINFO;
use Net::LDNS::RR::NS;
use Net::LDNS::RR::NSAP;
use Net::LDNS::RR::NSEC;
use Net::LDNS::RR::NSEC3;
use Net::LDNS::RR::NSEC3PARAM;
use Net::LDNS::RR::NULL;
use Net::LDNS::RR::NXT;
use Net::LDNS::RR::PTR;
use Net::LDNS::RR::PX;
use Net::LDNS::RR::RKEY;
use Net::LDNS::RR::RP;
use Net::LDNS::RR::RRSIG;
use Net::LDNS::RR::RT;
use Net::LDNS::RR::SINK;
use Net::LDNS::RR::SOA;
use Net::LDNS::RR::SPF;
use Net::LDNS::RR::SRV;
use Net::LDNS::RR::SSHFP;
use Net::LDNS::RR::TA;
use Net::LDNS::RR::TALINK;
use Net::LDNS::RR::TKEY;
use Net::LDNS::RR::TLSA;
use Net::LDNS::RR::TXT;
use Net::LDNS::RR::TYPE;
use Net::LDNS::RR::UID;
use Net::LDNS::RR::UINFO;
use Net::LDNS::RR::UNSPEC;
use Net::LDNS::RR::URI;
use Net::LDNS::RR::WKS;
use Net::LDNS::RR::X25;

use Carp;

use overload '<=>' => \&do_compare, 'cmp' => \&do_compare, '""' => \&to_string;

sub new {
    my ( $class, $string ) = @_;

    if ( $string ) {
        return $class->new_from_string( $string );
    }
    else {
        croak "Must provide string to create RR";
    }
}

sub name {
    my ( $self ) = @_;

    return $self->owner;
}

sub do_compare {
    my ( $self, $other, $swapped ) = @_;

    return $self->compare( $other );
}

sub to_string {
    my ( $self ) = @_;

    return $self->string;
}

1;

=head1 NAME

Net::LDNS::RR - common baseclass for all classes representing resource records.

=head1 SYNOPSIS

    my $rr = Net::LDNS::RR->new('www.iis.se IN A 91.226.36.46');

=head1 OVERLOADS

This class overloads stringify and comparisons ('""', '<=>' and 'cmp').

=head1 CLASS METHOD

=over

=item new($string)

Creates a new RR object of a suitable subclass, given a string representing an RR in common presentation format.

=back

=head1 INSTANCE METHODS

=over

=item owner()

=item name()

These two both return the owner name of the RR.

=item ttl()

Returns the ttl of the RR.

=item type()

Return the type of the RR.

=item class()

Returns the class of the RR.

=item string()

Returns a string with the RR in presentation format.

=item do_compare($other)

Calls the XS C<compare> method with the arguments it needs, rather than the ones overloading gives.

=item to_string

Calls the XS C<string> method with the arguments it needs, rather than the ones overloading gives. Functionally identical to L<string()> from the
Perl level, except for being a tiny little bit slower.

=item rd_count()

The number of RDATA objects in this RR.

=item rdf($postion)

The raw data of the RDATA object in the given position. The first item is in
position 0. If an attempt is made to fetch RDATA from a position that doesn't
have any, an exception will be thrown.

=back
