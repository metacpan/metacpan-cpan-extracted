#!/usr/bin/perl

package Net::BGP::Notification;

use strict;
use vars qw( $VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS @ERRORS );

## Inheritance and Versioning ##

@ISA     = qw( Exporter );
$VERSION = '0.07';

## Module Imports ##

use Exporter;
use Carp;

## BGP Protocol Error Code and Subcode Enumerations ##

sub BGP_ERROR_CODE_MESSAGE_HEADER             {  1 }
sub BGP_ERROR_CODE_OPEN_MESSAGE               {  2 }
sub BGP_ERROR_CODE_UPDATE_MESSAGE             {  3 }
sub BGP_ERROR_CODE_HOLD_TIMER_EXPIRED         {  4 }
sub BGP_ERROR_CODE_FINITE_STATE_MACHINE       {  5 }
sub BGP_ERROR_CODE_CEASE                      {  6 }

sub BGP_ERROR_SUBCODE_NULL                    {  0 }

sub BGP_ERROR_SUBCODE_CONN_NOT_SYNC           {  1 }
sub BGP_ERROR_SUBCODE_BAD_MSG_LENGTH          {  2 }
sub BGP_ERROR_SUBCODE_BAD_MSG_TYPE            {  3 }

sub BGP_ERROR_SUBCODE_BAD_VERSION_NUM         {  1 }
sub BGP_ERROR_SUBCODE_BAD_PEER_AS             {  2 }
sub BGP_ERROR_SUBCODE_BAD_BGP_ID              {  3 }
sub BGP_ERROR_SUBCODE_BAD_OPT_PARAMETER       {  4 }
sub BGP_ERROR_SUBCODE_AUTH_FAILURE            {  5 }
sub BGP_ERROR_SUBCODE_BAD_HOLD_TIME           {  6 }

sub BGP_ERROR_SUBCODE_MALFORMED_ATTR_LIST     {  1 }
sub BGP_ERROR_SUBCODE_BAD_WELL_KNOWN_ATTR     {  2 }
sub BGP_ERROR_SUBCODE_MISSING_WELL_KNOWN_ATTR {  3 }
sub BGP_ERROR_SUBCODE_BAD_ATTR_FLAGS          {  4 }
sub BGP_ERROR_SUBCODE_BAD_ATTR_LENGTH         {  5 }
sub BGP_ERROR_SUBCODE_BAD_ORIGIN_ATTR         {  6 }
sub BGP_ERROR_SUBCODE_AS_ROUTING_LOOP         {  7 }
sub BGP_ERROR_SUBCODE_BAD_NEXT_HOP_ATTR       {  8 }
sub BGP_ERROR_SUBCODE_BAD_OPT_ATTR            {  9 }
sub BGP_ERROR_SUBCODE_BAD_NLRI                { 10 }
sub BGP_ERROR_SUBCODE_BAD_AS_PATH             { 11 }

## Export Tag Definitions ##

@ERRORS = qw(
    BGP_ERROR_CODE_MESSAGE_HEADER
    BGP_ERROR_CODE_OPEN_MESSAGE
    BGP_ERROR_CODE_UPDATE_MESSAGE
    BGP_ERROR_CODE_HOLD_TIMER_EXPIRED
    BGP_ERROR_CODE_FINITE_STATE_MACHINE
    BGP_ERROR_CODE_CEASE
    BGP_ERROR_SUBCODE_NULL
    BGP_ERROR_SUBCODE_CONN_NOT_SYNC
    BGP_ERROR_SUBCODE_BAD_MSG_LENGTH
    BGP_ERROR_SUBCODE_BAD_MSG_TYPE
    BGP_ERROR_SUBCODE_BAD_VERSION_NUM
    BGP_ERROR_SUBCODE_BAD_PEER_AS
    BGP_ERROR_SUBCODE_BAD_BGP_ID
    BGP_ERROR_SUBCODE_BAD_OPT_PARAMETER
    BGP_ERROR_SUBCODE_AUTH_FAILURE
    BGP_ERROR_SUBCODE_BAD_HOLD_TIME
    BGP_ERROR_SUBCODE_MALFORMED_ATTR_LIST
    BGP_ERROR_SUBCODE_BAD_WELL_KNOWN_ATTR
    BGP_ERROR_SUBCODE_MISSING_WELL_KNOWN_ATTR
    BGP_ERROR_SUBCODE_BAD_ATTR_FLAGS
    BGP_ERROR_SUBCODE_BAD_ATTR_LENGTH
    BGP_ERROR_SUBCODE_BAD_ORIGIN_ATTR
    BGP_ERROR_SUBCODE_AS_ROUTING_LOOP
    BGP_ERROR_SUBCODE_BAD_NEXT_HOP_ATTR
    BGP_ERROR_SUBCODE_BAD_OPT_ATTR
    BGP_ERROR_SUBCODE_BAD_NLRI
    BGP_ERROR_SUBCODE_BAD_AS_PATH
);

@EXPORT      = ();
@EXPORT_OK   = ( @ERRORS );
%EXPORT_TAGS = (
    errors => [ @ERRORS ],
    ALL    => [ @EXPORT, @EXPORT_OK ]
);

## Public Methods ##

sub new
{
    my $class = shift();
    my ($arg, $value);

    my $this = {
        _error_code    => undef,
        _error_subcode => undef,
        _error_data    => undef
    };

    bless($this, $class);

    while ( defined($arg = shift()) ) {
        $value = shift();

        if ( $arg =~ /errorcode/i ) {
            $this->{_error_code} = $value;
        }
        elsif ( $arg =~ /errorsubcode/i ) {
            $this->{_error_subcode} = $value;
        }
        elsif ( $arg =~ /errordata/i ) {
            $this->{_error_data} = $value;
        }
        else {
            die("unrecognized argument $arg\n");
        }
    }

    defined $this->{_error_code} or croak "ErrorCode not defined";
    defined $this->{_error_subcode}
        or $this->{_error_subcode} = BGP_ERROR_SUBCODE_NULL;

    return ( $this );
}

sub throw {
    my $class = shift;
    my $notif = $class->new(@_);
    die $notif;
}

sub error_code
{
    my $this = shift();
    return ( $this->{_error_code} );
}

sub error_subcode
{
    my $this = shift();
    return ( $this->{_error_subcode} );
}

sub error_data
{
    my $this = shift();
    return ( $this->{_error_data} );
}

## Private Methods ##

## POD ##

=pod

=head1 NAME

Net::BGP::Notification - Class encapsulating BGP-4 NOTIFICATION message

=head1 SYNOPSIS

    use Net::BGP::Notification;

    $error = Net::BGP::Notification->new(
        ErrorCode    => $error_code,
        ErrorSubCode => $error_subcode,
        ErrorData    => $error_data
    );

    $error_code    = $error->error_code();
    $error_subcode = $error->error_subcode();
    $error_data    = $error->error_data();

=head1 DESCRIPTION

This module encapsulates the data contained in a BGP-4 NOTIFICATION message.
It provides a constructor, and accessor methods for each of the Error Code,
Error Subcode, and Error Data fields of a NOTIFICATION. It is unlikely that
user programs will need to instantiate B<Net::BGP::Notification> objects
directly. However, when an error occurs and a NOTIFICATION message is sent
or received by a BGP peering session established with the B<Net::BGP>
module, a reference to a B<Net::BGP::Notification> object will be passed
to the corresponding user callback subroutine. The subroutine can then use
the accessor methods provided by this module to examine the details of the
NOTIFICATION message.

=head1 METHODS

I<new()> - create a new Net::BGP::Notification object

    $error = Net::BGP::Notification->new(
        ErrorCode    => $error_code,
        ErrorSubCode => $error_subcode,
        ErrorData    => $error_data
    );

This is the constructor for Net::BGP::Notification objects. It returns a
reference to the newly created object. The following named parameters may
be passed to the constructor.

=head2 ErrorCode

This parameter corresponds to the Error Code field of a NOTIFICATION
message. It must be provided to the constructor.

=head2 ErrorSubCode

This parameter corresponds to the Error Subcode field of a NOTIFICATION
message. It may be omitted, in which case the field defaults to the null
(0) subcode value.

=head2 ErrorData

This parameter corresponds to the Error Data field of a NOTIFICATION
message. It may be omitted, in which case the field defaults to a null
(zero-length) value.

I<throw()> - create a Notification object and throw an exception

    Net::BGP::Notification->throw( same args as new );

I<error_code()> - retrieve the value of the Error Code field

    $error_code = $error->error_code();

I<error_subcode()> - retrieve the value of the Error Subcode field

    $error_subcode = $error->error_subcode();

I<error_data()> - retrieve the value of the Error Data field

    $error_data = $error->error_data();

=head1 SEE ALSO

B<Net::BGP>, B<Net::BGP::Process>, B<Net::BGP::Peer>,
B<Net::BGP::Update>

=head1 AUTHOR

Stephen J. Scheck <code@neurosphere.com>

=cut

## End Package Net::BGP::Notification ##

1;
