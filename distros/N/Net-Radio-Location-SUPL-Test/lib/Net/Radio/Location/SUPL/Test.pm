package Net::Radio::Location::SUPL::Test;

use strict;
use warnings;

use 5.010;

use Carp qw/croak/;

use Digest::SHA;
use List::Util qw(first);
use Log::Any qw($log);
use Params::Util qw(_HASH _STRING);

use Socket (
    qw(
      AF_INET6 PF_INET6 SOCK_RAW SOCK_STREAM INADDR_ANY SOCK_DGRAM
      AF_INET SO_REUSEADDR SO_REUSEPORT AF_UNSPEC SO_BROADCAST
      sockaddr_in
      )
);

use Net::Radio::Modem ();

use Net::Radio::Location::SUPL::XS;
use Net::Radio::Location::SUPL::MainLoop;

=head1 NAME

Net::Radio::Location::SUPL::Test - Run Test Use-Cases for SUPL

=head1 DESCRIPTION

This module implements state machine for handling SUPL packets.

The ASN.1 Compiler L<http://lionet.info/asn1c/compiler.html> is used
bleeding edge from the github repository found at
C<git://github.com/vlm/asn1c.git>.
The used asn1 skeletons has some patches as C<patches/asn1c/> shows.
It's recommended to apply them before regenerating C sources from
the ASN.1 source files.

See L<Net::Radio::Location::SUPL::XS> for details about the implemented
SUPL capabilities.

Following documents has been used for implementation:

=over 4

=item *

Open Mobile Alliance
Secure UserPlace Location Architecture Candidate Version 1.0, 22th Jan 2007

OMA-AD-SUPL-V1_0-20070122-C

=back

=head1 METHODS

=cut

our $VERSION = '0.001';

=head2 new

instantiates new Net::Radio::Location::SUPL::Test state machine

=cut

sub new
{
    my ( $class, %cfg ) = @_;

    my $self = bless( { config => \%cfg }, $class );

    my $modem_api_cfg = $self->{config}->{'modem-api'};
    $modem_api_cfg->{instance} //= Net::Radio::Modem->new( @$modem_api_cfg{ 'adapter', 'params' } );

    return $self;
}

{    #protect global variables
    my $connection_id = 0;
    sub _get_next_session_id { return ++$connection_id; }

    my %connect_pkgs;
    my %domain_abbrevs = (
                           IPV4   => AF_INET,
                           IPV6   => AF_INET6,
                           UNSPEC => AF_UNSPEC,
                         );

    sub _init_connect_pkgs
    {
        eval {
            require IO::Socket::SSL;
            $connect_pkgs{"IO::Socket::SSL"} = 1;
        };
        eval {
            require IO::Socket::INET;
            $connect_pkgs{"IO::Socket::INET"} = 1;
        };
        eval {
            require IO::Socket::INET6;
            $connect_pkgs{"IO::Socket::INET6"} = 1;
        };
    }

    sub _can_ipv6
    {
        keys(%connect_pkgs) or _init_connect_pkgs();
        $connect_pkgs{"IO::Socket::INET6"};
    }
    sub _can_ssl { keys(%connect_pkgs) or _init_connect_pkgs(); $connect_pkgs{"IO::Socket::SSL"} }

    sub _connect
    {
        my ( $self, %params ) = @_;

        keys(%connect_pkgs) or _init_connect_pkgs();

        my ( $io_api, $addr, $port );
        my %connect_params;

        if ( defined( $self->{config}->{connect}->{ssl} ) )
        {
            if ( $self->{config}->{connect}->{ssl} && !_can_ssl() )
            {
                return $log->error("ssl configured but missing IO::Socket::SSL");
            }
            elsif ( $self->{config}->{connect}->{ssl} )
            {
                $io_api = "IO::Socket::SSL";
                # check whether SSL_hostname is a required parameter
            }
        }

        if ( defined( $self->{config}->{connect}->{target}->{domain} ) )
        {
            my $domain = uc( $self->{config}->{connect}->{target}->{domain} );
            if ( defined( $domain_abbrevs{$domain} ) )
            {
                $connect_params{Domain} = $domain_abbrevs{$domain};
            }
            else
            {
                $log->warningf(
                    "Invalid IP domain '%s' - allowed are 'IPv4', 'IPv6' and 'unspec'. Fall back to 'unspec'."
                );
            }
        }

        # IO::Socket::INET6( Domain => AF_INET, ... ) speaks IPv4
        $io_api //= _can_ipv6() ? "IO::Socket::INET6" : "IO::Socket::INET";

        $port = $params{port};
        $port //=
            $self->{config}->{connect}->{ssl}
          ? $self->{config}->{connect}->{target}->{supl_port} // 7275
          : $self->{config}->{connect}->{target}->{ulp_port}
          // 7276;    # find ULP spec telling default port for non-secure communication

        if ( defined( $params{host} ) )
        {
            $addr = $params{host};
        }
        elsif ( defined( $self->{config}->{connect}->{target}->{host} ) )
        {
            $addr = $self->{config}->{connect}->{target}->{host};
        }
        else
        {
            $addr = $self->_calc_hslp_from_imsi();    # XXX crash's - inimplemented!
        }

        $self->{connection} = $io_api->new(
                                            PeerAddr => $addr,
                                            PeerPort => $port,
                                            Proto    => "tcp",
                                            %connect_params
                                          )
          or return
          $log->errorf( "Can't connect to %s[:%d]: %s",
                        $io_api eq "IO::Socket::SSL" ? IO::Socket::SSL::errstr() : $@ );

        return $self->{connection};
    }

    sub _get_modem_info
    {
        my ( $self, $properties ) = @_;
        my $modem_api = $self->{config}->{'modem-api'}->{instance};
        my $modem;
        if ( _HASH( $self->{config}->{'modem-api'}->{match} ) )
        {
            my $match        = $self->{config}->{'modem-api'}->{match};
            my @match_keys   = keys %{$match};
            my @match_values = values %{$match};
            $modem = first(
                sub {
                    my $mob = $_;    # modem object path
                    my @v = map { $modem_api->get_modem_property( $mob, $_ ) } @match_keys;
                    @v ~~ @match_values;
                },
                $modem_api->get_modems()
                          );
            $log->debugf( "Found modem %s matching %s", $modem // 'n/a', $match );
        }
        else
        {
            $modem = first { defined($_) } $modem_api->get_modems();
            $log->debugf( "Using first modem %s", $modem // 'n/a' );
        }
        $modem or return;
        my @props = map { $modem_api->get_modem_property( $modem, $_ ) } @$properties;
        $log->debugf( "Extracted %s (%s) from modem %s", \@props, $properties, $modem // 'n/a' );
        return @props;
    }

    sub _calculate_response_addr
    {
        my $self = shift;
        my %mobile_ident;
        @mobile_ident{qw(mcc mnc)} = $self->_get_modem_info( [qw(MCC MNC)] );
        my $response_addr = sprintf( "h-slp.mnc%03d.mcc%03d.pub.3gppnetwork.org",
                                     0 + $mobile_ident{mnc}, 0 + $mobile_ident{mcc} );
        return $response_addr;
    }
}

=head2 respond($pdu,@typenames)

Takes a given SUPL Protocol Data Unit (as instance of
Net::Radio::Location::SUPL::XS::ULP_PDU_t) and the associated type names
(eg. C<qw(suplposinit)> or C<qw(suplpos assistanceDataAck)>).

Given PDU is encoded, sent to H-SLP via open socket and in case of an
SUPL END PDU, the connection is terminated. Some logging and error handling
around encoding/sending completes the respond action.

=cut

sub respond
{
    my ( $self, $pdu, @response_typenames ) = @_;

    my $response_struct = $self;
    for my $response_typename (@response_typenames)
    {
        $response_struct = $response_struct->{$response_typename};
    }
    $response_struct->{pdu} //= $pdu;
    eval {
        # encode packet
        $log->debugf( "encoding response ...\n%s", $response_struct->{pdu}->xml_dump() );
        $response_struct->{packet} = $response_struct->{pdu}->encode();
    };
    if ($@)
    {
        $log->errorf( "Error encoding PDU: %s", $@ );
        $self->_terminate();
        return;
    }

    # send response
    $self->{connection}->syswrite( $response_struct->{packet} );

    if ( $response_struct->{pdu}->{message}->{present} ==
         $Net::Radio::Location::SUPL::XSc::UlpMessage_PR_msSUPLEND )
    {
        $self->_terminate();
    }

    return;
}

my %requested_assist_data = (
     almanacRequested  => Net::Radio::Location::SUPL::XS::reqassistdata_almanacRequested,
     utcModelRequested => Net::Radio::Location::SUPL::XS::reqassistdata_utcModelRequested,
     ionosphericModelRequested =>
       Net::Radio::Location::SUPL::XS::reqassistdata_ionosphericModelRequested,
     dgpsCorrectionsRequested =>
       Net::Radio::Location::SUPL::XS::reqassistdata_dgpsCorrectionsRequested,
     referenceLocationRequested =>
       Net::Radio::Location::SUPL::XS::reqassistdata_referenceLocationRequested,
     referenceTimeRequested => Net::Radio::Location::SUPL::XS::reqassistdata_referenceTimeRequested,
     acquisitionAssistanceRequested =>
       Net::Radio::Location::SUPL::XS::reqassistdata_acquisitionAssistanceRequested,
     realTimeIntegrityRequested =>
       Net::Radio::Location::SUPL::XS::reqassistdata_realTimeIntegrityRequested,
);

=head2 prepare_supl_response($pdu)

Prepares a response SUPL PDU by copying SlpSessionId into a newly created SUPL PDU.

=cut

sub prepare_supl_response
{
    my ( $self, $supl_pdu ) = @_;

    # built SUPLPOSINIT/AUTHREQ/END
    my $pdu = Net::Radio::Location::SUPL::XS::ULP_PDU_t->new();

    $pdu->copy_SessionId($supl_pdu);

    return $pdu;
}

=head2 begin_ni_supl_seesion

Begins a network initiated SUPL session.

=cut

sub begin_ni_supl_seesion
{
    my ( $self, %params ) = @_;
    my ( $packet, $supl_pdu ) = @params{ "supl_packet", "supl_pdu" };

    $self->{suplinit}->{pdu}    = $supl_pdu;
    $self->{suplinit}->{packet} = $packet;

    my %mobile_ident;
    @mobile_ident{qw(mcc mnc lac cellid imsi msisdn)} =
      $self->_get_modem_info( [qw(MCC MNC LAC CI IMSI MSISDN)] );

    my $pdu = $self->prepare_supl_response($supl_pdu);
    $pdu->setSetSessionId_to_imsi( _get_next_session_id(), $mobile_ident{imsi} );
    # $pdu->setSetSessionId_to_msisdn( _get_next_session_id(), $mobile_ident{msisdn}->[0] // "4915220490147" );

    my ( $response_type, $response_addr, $response_typename, $response_supl );
    my $supl_init = $supl_pdu->{message}->{choice}->{msSUPLINIT};
    # check proxy mode
    if ( $supl_init->{sLPMode} == Net::Radio::Location::SUPL::XS::SLPMode_proxy )
    {
        $log->debug("NI packet wants proxy mode");
        $response_type     = $Net::Radio::Location::SUPL::XSc::UlpMessage_PR_msSUPLPOSINIT;
        $response_typename = "suplposinit";
        $pdu->set_message_type($response_type);
        $response_supl = $pdu->{message}->{choice}->{msSUPLPOSINIT};
    }
    else
    {
        # XXX might require additional effort to send SUPLEND in nonProxy
        #     mode which might make rejection of nonProxy mode superfluous
        $log->warning("nonProxy mode not supported");
        $response_type     = $Net::Radio::Location::SUPL::XSc::UlpMessage_PR_msSUPLEND;
        $response_typename = "suplend";
        $pdu->set_message_type($response_type);
        $response_supl = $pdu->{message}->{choice}->{msSUPLEND};
    }

    # check reply address (fqdn, ip...)
    # XXX allow config override?
    if ( $supl_init->{sLPAddress}->is_fqdn() )
    {
        $response_addr = $supl_init->{sLPAddress}->{choice}->{fQDN};
        # check whether config wants to override
    }
    else
    {
        $response_addr =
          defined( $self->{config}->{connect}->{target}->{host} )
          ? $self->{config}->{connect}->{target}->{host}
          : $self->_calculate_response_addr();
    }

    # connect ...
    $self->_connect( host => $response_addr ) or return;

    # register at MainLoop (or better in handle_pdu?)
    Net::Radio::Location::SUPL::MainLoop->add($self);

    # compute verification checksum
    my $chksum = Digest::SHA::hmac_sha1( $packet, $response_addr );
    length($chksum) != 8 and $chksum = substr( $chksum, 0, 8 );

    if ( $response_typename eq "suplposinit" )
    {
        $response_supl->set_capabilities(
                                 Net::Radio::Location::SUPL::XS::setcap_pos_tech_agpsSETBased(),
#                                 Net::Radio::Location::SUPL::XS::setcap_pos_tech_autonomousGPS(),
                                 Net::Radio::Location::SUPL::XS::PrefMethod_noPreference(),
#                                 Net::Radio::Location::SUPL::XS::PrefMethod_agpsSETBasedPreferred(),
                                 Net::Radio::Location::SUPL::XS::setcap_pos_proto_rrlp()
        );
        if ( $mobile_ident{cellid} > 65535 )
        {
            $response_supl->{locationId}->{status} = Net::Radio::Location::SUPL::XS::Status_current;
            $response_supl->set_wcdma_location_info( map { 0 + $_ }
                                                     ( @mobile_ident{qw(mcc mnc cellid)} ) );
        }
        elsif ( defined( $mobile_ident{lac} ) )
        {
            $response_supl->{locationId}->{status} = Net::Radio::Location::SUPL::XS::Status_current;
            $response_supl->set_gsm_location_info(
                map { 0 + $_ } ( @mobile_ident{qw(mcc mnc lac cellid)} ),
                1    # ta -- Terminal Adaptor
                                                 );
        }
        else
        {
            $response_supl->{locationId}->{status} = Net::Radio::Location::SUPL::XS::Status_stale;
            $log->warning("16-bit cellid and no LocationAreaCode -- can't construct CellInfo");
        }

        if ( $self->{config}->{"SUPLPOSINIT"}->{"estimated-location"} )
        {
            my $pos_cfg = $self->{config}->{"mocked-location"};
            my ( $latitude, $longitude ) = @$pos_cfg{ "latitude", "longitude" };
            $log->debugf( "mocked-pos: %s", $pos_cfg );
            $response_supl->set_position_estimate( time,
                                                   int( $latitude < 0 ),
                                                   abs( int($latitude) ),
                                                   int($longitude) );
        }

        if ( _HASH( $self->{config}->{SUPLPOSINIT}->{"request-assistant-data"} ) )
        {
            my $reqAssistData = 0;
            while ( my ( $assist, $enabled ) =
                    each( %{ $self->{config}->{SUPLPOSINIT}->{"request-assistant-data"} } ) )
            {
                $enabled and $reqAssistData += $requested_assist_data{$assist};
            }
            $reqAssistData or $log->warning("requested-assist-data given but nothing enabled");
            $response_supl->set_requested_assist_data($reqAssistData);
            # set_requested_assist_navigation_modell ...
        }
    }

    # verification hash
    $response_supl->{ver} = $chksum;

    $self->respond( $pdu, $response_typename );

    return;
}

=head2 send_supl_rrlp_response($supl_pdu, $rrlp_resp_pdu, $resp_typename)

Sends out an RRLP PDU embedded in a SUPL POS packet.

Parameters:

=over 8

=item C<$supl_pdu>

SUPL PDU to be responded. Required to extract session id's for the answer
PDU.

=item C<$rrlp_resp_pdu>

Prepared RRLP PDU to embed into created SUPL POS message.

=item C<$resp_typename>

Typename of the answer (eg. msrPositionResp)

=back

=cut

sub send_supl_rrlp_response
{
    my ( $self, $supl_pdu, $rrlp_resp_pdu, $resp_name ) = @_;

    my $pdu = $self->prepare_supl_response($supl_pdu);
    $pdu->set_message_type($Net::Radio::Location::SUPL::XSc::UlpMessage_PR_msSUPLPOS);

    my $supl_pos = $pdu->{message}->{choice}->{msSUPLPOS};

    $log->debugf( "rrlp response\n%s", $rrlp_resp_pdu->xml_dump() );

    $supl_pos->{posPayLoad}->{present} =
      $Net::Radio::Location::SUPL::XSc::PosPayLoad_PR_rrlpPayload;
    my $rrlp_pkt = $rrlp_resp_pdu->encode();
    $log->debugf( "encoded rrlp reponse pdu: [%s](%d)",
                  unpack( "H*", $rrlp_pkt ),
                  length($rrlp_pkt) );
    $supl_pos->{posPayLoad}->{choice}->{rrlpPayload} = $rrlp_pkt;

    $self->respond( $pdu, "suplpos", $resp_name );

    return;
}

my @set_posEstimate_params = (
                               [ "latitude", "longitude" ],
                               [ "latitude", "longitude", "uncertainty" ],
                               [
                                  "latitude",                  "longitude",
                                  "uncertainty semi-major",    "uncertainty semi-minor",
                                  "orientation of major axis", "confidence"
                               ],
                               [ "latitude", "longitude", "altitude" ],
                               [
                                  "latitude",               "longitude",
                                  "altitude",               "uncertainty semi-major",
                                  "uncertainty semi-minor", "orientation of major axis",
                                  "uncertainty altitude",   "confidence"
                               ],
                               [
                                  "latitude",
                                  "longitude",
                                  "inner radius",
                                  "uncertainty radius",
                                  "offset angle",
                                  "inner angle",
                                  "included angle",
                                  "confidence"
                               ],
                             );

# Location_posEstimate_fixpoint_arith_multiplier
my $loc_fpmult = Net::Radio::Location::SUPL::XS::LocationInfo_t::get_fixpoint_arith_multiplier();
my %set_posEstimate_paramHook = (
                    "latitude"  => sub { ( int( $_[0] < 0 ), abs( int( $_[0] * $loc_fpmult ) ) ); },
                    "longitude" => sub { int( $_[0] * $loc_fpmult ); },
                    "altitude"  => sub { ( int( $_[0] < 0 ), abs( int( $_[0] ) ) ); },
                                );

sub _prepare_posEstimate_settings
{
    my $pos_cfg = $_[0];
    my @params;
    my @sp_in = sort keys %$pos_cfg;

    foreach my $spep (@set_posEstimate_params)
    {
        my @sp_chk = sort @$spep;
        $log->debugf( "Checking set_posEstimate parameter list: %s ~~ %s", \@sp_in, \@sp_chk );
        @sp_in ~~ @sp_chk or next;
        $log->debugf("Matched");
        @params = map {
            defined( $set_posEstimate_paramHook{$_} )
              ? &{ $set_posEstimate_paramHook{$_} }( $pos_cfg->{$_} )
              : int( $pos_cfg->{$_} )
        } @$spep;
        $log->debugf( "Calling with %s", \@params );
        return @params;
    }

    $log->errorf( "Couldn't determin right set_posEstimate parameter list from",
                  [ keys %$pos_cfg ] );

    return;
}

=head2 handle_supl_pos_rrlp_packet

Handles the reaction of an incoming SUPL POS packet with an embedded
RRLP PDU.

=over 8

=item *

assistanceData will be acknowledged (assistanceDataAck)

=item *

msrPositionReq will be responded with configured coordinates until access to
NMEA standard documents is available and the time is provided to implement
GSM location extraction.

=item *

Everything else is responded with a protocolError.

=back

=cut

sub handle_supl_pos_rrlp_packet
{
    my ( $self, %params ) = @_;
    my ( $supl_pkt, $supl_pdu, $rrlp_pkt, $rrlp_pdu ) =
      @params{ "supl_packet", "supl_pdu", "rrlp_packet", "rrlp_pdu" };

    $log->debugf( "embedded rrlp packet:\n%s", $rrlp_pdu->xml_dump() );

    my $rrlp_resp_pdu = Net::Radio::Location::SUPL::XS::RRLP_PDU_t->new();

    $rrlp_resp_pdu->{referenceNumber} = $rrlp_pdu->{referenceNumber};
    my $rrlp_resp_type;

    given ( $rrlp_pdu->{component}->{present} )
    {
        when ($Net::Radio::Location::SUPL::XSc::RRLP_Component_PR_assistanceData)
        {
            $self->{suplpos}->{assistanceData}->{pdu}    = $supl_pdu;
            $self->{suplpos}->{assistanceData}->{packet} = $supl_pkt;

            # XXX probably RRLP_Component_PR_protocolError?
            $rrlp_resp_pdu->set_component_type(
                             $Net::Radio::Location::SUPL::XSc::RRLP_Component_PR_assistanceDataAck);
            $rrlp_resp_type = "assistanceDataAck";
        }
        when ($Net::Radio::Location::SUPL::XSc::RRLP_Component_PR_msrPositionReq)
        {
            $self->{suplpos}->{msrPositionReq}->{pdu}    = $supl_pdu;
            $self->{suplpos}->{msrPositionReq}->{packet} = $supl_pkt;

            my $pos_cfg          = $self->{config}->{"mocked-location"};
            my @set_posEst_parms = _prepare_posEstimate_settings($pos_cfg);
            if (@set_posEst_parms)
            {
                $rrlp_resp_pdu->set_component_type(
                                $Net::Radio::Location::SUPL::XSc::RRLP_Component_PR_msrPositionRsp);
                my $locationInfo =
                  $rrlp_resp_pdu->{component}->{choice}->{msrPositionRsp}->{locationInfo} =
                  Net::Radio::Location::SUPL::XS::LocationInfo_t->new(
                       65535,    # ignored by GMLC between 42432..65535 - see 3GPP TS 44.031 A.3.2.4
                       1         # 3D fix
                                                                     );

                # see TS 23.032 for encoding
                $locationInfo->set_posEstimate(@set_posEst_parms);
                $rrlp_resp_type = "msrPositionRsp";
            }
            else
            {
                $rrlp_resp_pdu->set_component_type(
                                 $Net::Radio::Location::SUPL::XSc::RRLP_Component_PR_protocolError);
                # incorrect data
                $rrlp_resp_pdu->{component}->{choice}->{protocolError}->{errorCause} = 2;
                $rrlp_resp_type = "protocolError";
            }
        }
        default
        {
            $rrlp_resp_pdu->set_component_type(
                                 $Net::Radio::Location::SUPL::XSc::RRLP_Component_PR_protocolError);
            # missing component
            $rrlp_resp_pdu->{component}->{choice}->{protocolError}->{errorCause} = 1;
            $rrlp_resp_type = "protocolError";
        }
    }

    $self->send_supl_rrlp_response( $supl_pdu, $rrlp_resp_pdu, $rrlp_resp_type );

    return;
}

=head2 handle_supl_pdu($pkt;$pdu)

Starts a new flow of network initiated SUPL.

=cut

sub handle_supl_pdu
{
    my ( $self, $supl_pkt, $supl_pdu ) = @_;

    _STRING($supl_pkt) or croak "Invalid argument for \$supl_pkt";

    $supl_pdu //= Net::Radio::Location::SUPL::XS::decode_ulp_pdu($supl_pkt);

    $log->is_debug()
      and $log->debugf( "received pdu containing message type %d of %d bytes length",
                        $supl_pdu->{message}->{present},
                        $supl_pdu->{length} );
    $log->is_debug() and $log->debugf( "pdu: %s", $supl_pdu->xml_dump() );

    # decode_ulp_pdu croaks on error ...
    given ( $supl_pdu->{message}->{present} )
    {
        when ($Net::Radio::Location::SUPL::XSc::UlpMessage_PR_msSUPLINIT)
        {
            $self->begin_ni_supl_seesion( supl_packet => $supl_pkt,
                                          supl_pdu    => $supl_pdu );
        }
        when ($Net::Radio::Location::SUPL::XSc::UlpMessage_PR_msSUPLPOS)
        {
            my $supl_pos = $supl_pdu->{message}->{choice}->{msSUPLPOS};
            given ( $supl_pos->{posPayLoad}->{present} )
            {
                when ($Net::Radio::Location::SUPL::XSc::PosPayLoad_PR_rrlpPayload)
                {
                    my $rrlp_pkt = $supl_pos->{posPayLoad}->{choice}->{rrlpPayload};
                    $self->handle_supl_pos_rrlp_packet(
                              supl_packet => $supl_pkt,
                              supl_pdu    => $supl_pdu,
                              rrlp_packet => $rrlp_pkt,
                              rrlp_pdu => Net::Radio::Location::SUPL::XS::RRLP_PDU_t->new($rrlp_pkt)
                    );
                }
                default
                {
                    $log->errorf(
                                  "Unsupported protocol embedded in SUPLPOS: %d, supported: %d",
                                  $supl_pos->{posPayLoad}->{present},
                                  $Net::Radio::Location::SUPL::XSc::PosPayLoad_PR_rrlpPayload
                                );
                    $self->_terminate();
                }
            }
        }
        when ($Net::Radio::Location::SUPL::XSc::UlpMessage_PR_msSUPLEND)
        {
            $self->_terminate();
        }
        default
        {
            # ...
            $self->_terminate();
        }
    }

    return;
}

sub _terminate
{
    my $self = shift;

    Net::Radio::Location::SUPL::MainLoop->remove($self);
    my @supls = grep { $_ =~ m/^supl/ and _HASH( $self->{$_} ) } keys( %{$self} );
    foreach my $supl (@supls)
    {
        defined( $self->{$supl}->{packet} ) and delete $self->{$supl}->{packet};
        defined( $self->{$supl}->{pdu} )    and delete $self->{$supl}->{pdu};
    }
    if ( $self->{connection} )
    {
        $self->{connection}->close();
        delete $self->{connection};
    }

    return;
}

=head2 trigger_read

Is called from the main-loop when the managed socket has incoming data.

=cut

sub trigger_read
{
    my $self = shift;

    $log->debug("trigger_read()");

    my $pkt = '';
    my $pending;
    do
    {
        my $buf;
        my $rb = $self->{connection}->sysread( $buf, 4096 );
        unless ( defined $rb )
        {
            $log->errorf( "Error receiving data: %s", $! );
            # XXX what to do from here?
            $self->_terminate();
        }
        $pkt .= $buf;
        $pending = $self->{connection}->pending();
        $log->debugf( "Received %d bytes, %d pending", $rb, $pending );
    } while ( $pending > 0 );
    $log->debugf( "Entire data of %d bytes read", length $pkt );

    # triggered but no data ==> eof, see perldoc -f sysread
    length($pkt) or return $self->_terminate();

    $self->{recvbuf} and $pkt = $self->{recvbuf} . $pkt;
    my $supl_pdu;
    eval { $supl_pdu = Net::Radio::Location::SUPL::XS::decode_ulp_pdu($pkt); };
    if ($@)
    {
        if ( $@ =~ m/RC_WMORE/ )
        {
            $self->{recvbuf} = $pkt;
        }
        else
        {
            $log->errorf( "Error decoding received data: %s", $@ );
            # XXX what to do from here?
            $self->_terminate();
        }
    }
    else
    {
        delete $self->{recvbuf};
        $log->debugf( "Received [%s] via network", unpack( "H*", $pkt ) );
        $self->handle_supl_pdu( $pkt, $supl_pdu );
    }

    return;
}

=head2 get_read_trigger

Called by L<Net::Radio::Location::SUPL::MainLoop> to add the managed socket to the list of file
handles monitored for havind data to receive.

=cut

sub get_read_trigger
{
    defined( $_[0]->{connection} ) and return $_[0]->{connection}->fileno();
    return;
}

sub DESTROY
{
    my $self = shift;
    $self->{connection} and $self->{connection}->close();
    delete $self->{connection};
    return;
}

=head1 BUGS

Please report any bugs or feature requests to
C<bug-supl-test at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SUPL-Test>.
I will be notified, and then you'll automatically be notified of progress
on your bug as I make changes.

If you think you've found a bug then please read "How to Report Bugs
Effectively" by Simon Tatham:
L<http://www.chiark.greenend.org.uk/~sgtatham/bugs.html>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::Radio::Location::SUPL::Test

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=SUPL-Test>

If you think you've found a bug then please read "How to Report Bugs
Effectively" by Simon Tatham:
L<http://www.chiark.greenend.org.uk/~sgtatham/bugs.html>.

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/SUPL-Test>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/SUPL-Test>

=item * Search CPAN

L<http://search.cpan.org/dist/SUPL-Test/>

=back

=head2 Where can I go for help with a concrete version?

Bugs and feature requests are accepted against the latest version
only. To get patches for earlier versions, you need to get an
agreement with a developer of your choice - who may or not report the
issue and a suggested fix upstream (depends on the license you have
chosen).

=head2 Business support and maintenance

For business support you can contact Jens via his CPAN email
address rehsackATcpan.org. Please keep in mind that business
support is neither available for free nor are you eligible to
receive any support based on the license distributed with this
package.

=head1 ACKNOWLEDGEMENTS


=head1 AUTHOR

Jens Rehsack, C<< <rehsack at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Jens Rehsack.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
