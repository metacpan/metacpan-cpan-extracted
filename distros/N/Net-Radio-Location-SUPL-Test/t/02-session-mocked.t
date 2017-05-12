use strict;
use warnings;

use Test::More;

$INC{'IO/Socket/SSL.pm'} = 1;

package IO::Socket::SSL;

sub new
{
    my ($class) = @_;
    return
      bless(
             {
                in  => [],
                out => [],
             },
             $class
           );
}

sub sysread(\$$)
{
    my ( $self, $buf, $bufsize ) = @_;

    ${$buf} = shift @{ $self->{in} };

    return length ${$buf};
}

sub syswrite
{
    my ( $self, $pkt ) = @_;
    push( @{ $self->{out} }, $pkt );
    return length $pkt;
}

sub pending
{
    return 0;
}

sub fileno
{
    return -1;
}

sub close
{
}

package main;

use Net::Radio::Location::SUPL::Test;
use Net::Radio::Modem;

my %test_setup = (
    "modem-api" => {
                     "adapter" => "Static",
                     "params"  => {
                                   "/test_0" => {
                                                  IMSI => "262025558632366",
                                                  MNC  => "02",
                                                  MCC  => "262",
                                                  LAC  => "1601",
                                                  CI   => "98463414",
                                                }
                                 },
                     "match" => { "IMSI" => "262025558632366" }
                   },
    "connect" => {
                   "target" => {
                                 "host"      => "supl.vodafone.com",
                                 "supl_port" => 7275,
                                 "ulp_port"  => 7276,
                                 "domain"    => "IPv4",
                               },
                   "ssl" => 1,
                 },
    "mocked-location" => {
			   "latitude" => "6.768034",
			   "longitude" => "51.221195"
			 },
    "SUPLINIT" => {
                    "action" => "reply",
                    "modes"  => ["proxy"],
                  },
    "SUPLPOSINIT" => {
        #"request-assistant-data" => {
        #                        "almanacRequested"               => 1,
        #                        "utcModelRequested"              => 1,
        #                        "ionosphericModelRequested"      => 1,
        #                        "dgpsCorrectionsRequested"       => 1,
        #                        "referenceLocationRequested"     => 1,
        #                        "referenceTimeRequested"         => 1,
        #                        "acquisitionAssistanceRequested" => 1,
        #                        "realTimeIntegrityRequested"     => 1
        #},
        "estimated-location" => 1
                     },
    "SUPLPOS" => {}
                 );

my $supl_pkt = pack( "H*",
                     "002b0100004c4d0e0e110e3ad7107bd299abd33a81a34c80c1a21c75ae20f7a53357a6750346991990000a"
                   );
my $test = Net::Radio::Location::SUPL::Test->new(%test_setup);
$test->handle_supl_pdu($supl_pkt);

isa_ok( $test->{connection}, "IO::Socket::SSL", "SSL Connection established" );
cmp_ok( scalar( @{ $test->{connection}->{out} } ), "==", 1, "Response sent" );

SKIP:
{
    my $skip_cnt = 7;
    my $supl_pdu =
      eval { Net::Radio::Location::SUPL::XS::ULP_PDU_t->new( $test->{connection}->{out}->[0] ); };
    $@ and skip( "SUPL PDU decoding failed with $@", $skip_cnt );

    note( $supl_pdu->dump() );

    cmp_ok( $supl_pdu->{sessionID}->{setSessionID}->{sessionId},
            ">", 0, "Generated good Set Session ID number" );
    --$skip_cnt;
    cmp_ok( $supl_pdu->{sessionID}->{setSessionID}->{setId}->{present},
            "==",
            $Net::Radio::Location::SUPL::XSc::SETId_PR_imsi,
            "Generated good Set Session ID Set ID type" )
      or skip( "SetID isn't IMSI", $skip_cnt );
    --$skip_cnt;

    my $cfg_imsi = $test_setup{"modem-api"}->{"params"}->{"/test_0"}->{IMSI};
    $cfg_imsi .= "f" x (16 - length($cfg_imsi));
    $cfg_imsi =~ s/(\w)(\w)/$2$1/g;
    my $computed_imsi = unpack( "H*", $supl_pdu->{sessionID}->{setSessionID}->{setId}->{choice}->{imsi} );
    cmp_ok( $computed_imsi, "eq", $cfg_imsi, "Submitted correct IMSI to identify SET" );
    --$skip_cnt;

    my $slpSessionId = pack( "H*", "31343838" );
    cmp_ok( $supl_pdu->{sessionID}->{slpSessionID}->{sessionID},
            "eq", $slpSessionId, "Cloned SlpSessionId's session id correctly" );
    --$skip_cnt;
    cmp_ok( $supl_pdu->{sessionID}->{slpSessionID}->{slpId}->{present},
            "==",
            $Net::Radio::Location::SUPL::XSc::SLPAddress_PR_fQDN,
            "Generated good Slp Session ID Slp ID type" )
      or skip( "SlpID isn't FQDN", $skip_cnt );
    --$skip_cnt;
    cmp_ok( $supl_pdu->{sessionID}->{slpSessionID}->{slpId}->{choice}->{fQDN},
            "eq", "supl.vodafone.com", "Cloned correct SLP Address" );
    --$skip_cnt;

    cmp_ok( $supl_pdu->{message}->{present},
            "==",
            $Net::Radio::Location::SUPL::XSc::UlpMessage_PR_msSUPLPOSINIT,
            "Response is SUPLPOSINIT" )
      or skip( "No SUPLPOSINIT", $skip_cnt );
    --$skip_cnt;

    my $posinit = $supl_pdu->{message}->{choice}->{msSUPLPOSINIT};

    cmp_ok($skip_cnt, "==", 0, "Nothing left to be skipped (self control)");
}

done_testing();

