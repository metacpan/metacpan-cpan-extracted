#!/usr/bin/perl

package Net::BGP::Refresh;
use bytes;

use strict;
use vars qw( $VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS @AFI @SAFI );

## Inheritance and Versioning ##

@ISA     = qw( Exporter );
$VERSION = '0.07';

## Module Imports ##

use Exporter;
use Net::BGP::Notification qw( :errors );

## BGP Protocol Error Code and Subcode Enumerations ##


# http://www.iana.org/assignments/address-family-numbers
sub AFI_IP4             {  1 }
sub AFI_IP6             {  2 }

# http://www.iana.org/assignments/safi-namespace
sub SAFI_UNI            {  1 }
sub SAFI_MULTI          {  2 }
sub SAFI_BOTH           {  3 }
sub SAFI_MPLS           {  4 }

@AFI = qw(
	AFI_IP4
	AFI_IP6
	);

@SAFI = qw(
	SAFI_UNI
	SAFI_MULTI
	SAFI_BOTH
	SAFI_MPLS
	);

@EXPORT      = ();
@EXPORT_OK   = ( @AFI, @SAFI );
%EXPORT_TAGS = (
    afi  => [ @AFI ],
    safi => [ @SAFI ],
    ALL  => [ @EXPORT, @EXPORT_OK ]
);

## Public Methods ##

sub new
{
    my $class = shift();
    my ($arg, $value);

    my $this = {
        _afi    => AFI_IP4,
        _safi   => SAFI_BOTH
    };

    bless($this, $class);

    while ( defined($arg = shift()) ) {
        $value = shift();

        if ( $arg =~ /safi/i ) {
            $this->{_safi} = $value;
        }
        elsif ( $arg =~ /afi/i ) {
            $this->{_afi} = $value;
        }
        else {
            die("unrecognized argument $arg\n");
        }
    }

    return ( $this );
}

sub afi
{
    my $this = shift();
    return ( $this->{_afi} );
}

sub safi
{
    my $this = shift();
    return ( $this->{_safi} );
}

## Private Methods ##

sub _new_from_msg
{
    my ($class, $buffer) = @_;

    my $this = $class->new;

    $this->_decode_message($buffer);

    return $this;
}

sub _decode_message
{
    my ($this, $buffer) = @_;

    if ( length($buffer) != 4 ) {
        Net::BGP::Notification->throw(
            ErrorCode    => BGP_ERROR_CODE_FINITE_STATE_MACHINE
        );
    }

   ($this->{_afi},undef,$this->{_safi}) = unpack('ncc', $buffer);

   return undef;
}

sub _encode_message
{
    my $this = shift();

    # encode the message
    my $buffer = pack('ncc', $this->{_afi}, 0, $this->{_safi});

    return ( $buffer );
}

## POD ##

=pod

=head1 NAME

Net::BGP::Refresh - Class encapsulating BGP-4 REFRESH message

=head1 SYNOPSIS

    use Net::BGP::Refresh;

    $refresh = Net::BGP::Refresh->new(
        AFI      => $address_family_identifier,
        SAFI     => $subsequent_address_family_identifier
    );

    $address_family_identifier            = $error->afi();
    $subsequent_address_family_identifier = $error->safi();

    $peer->refresh($refresh);

=head1 DESCRIPTION

This module encapsulates the data contained in a BGP-4 REFRESH message as
specifed by RFC2918.
It provides a constructor, and accessor methods for each of the fields, AFI
and SAFI, of a REFRESH message.
To refresh the route table for a given address family, call the peer object's
I<refresh()> function with a B<Net::BGP::Refresh> object as argument.

=head1 METHODS

I<new()> - create a new Net::BGP::Refresh object

    $error = Net::BGP::Refresh->new(
        AFI      => $address_family_identifier,
        SAFI     => $subsequent_address_family_identifier
    );

This is the constructor for Net::BGP::Refresh objects. It returns a
reference to the newly created object. The following named parameters may
be passed to the constructor.

=head2 AFI

This parameter corresponds to the Address Family Identifier field of a REFRESH
message. Default is I<AFI_IP4>.

=head2 SAFI

This parameter corresponds to the Subsequent Address Family Identifier field of
a REFRESH message. Default is I<SAFI_BOTH>.

I<afi()> - retrieve the value of the Address Family Identifier field

    $address_family_identifier            = $error->afi();

I<safi()> - retrieve the value of the Subsequent Address Family Identifier field

    $subsequent_address_family_identifier = $error->safi();

=head1 SEE ALSO

B<Net::BGP>, B<Net::BGP::Process>, B<Net::BGP::Peer>,
B<Net::BGP::Notification>, B<Net::BGP::Update>

=head1 AUTHOR

Stephen J. Scheck <code@neurosphere.com>

=cut

## End Package Net::BGP::Notification ##

1;
