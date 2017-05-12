#!perl -T

use strict;
use warnings;

use Test::More;
use Test::Deep;

use Net::Radio::Modem;

my %test_data = (
                  '/test_0' => {
                                 MCC  => '364',
                                 MNC  => '390',
                                 IMSI => '364390123456789',
                                 SNR  => '4443794711',
                                 LAC  => '7532',
                                 CI   => '4711',
                               },
                  '/test_1' => {
                                 MCC  => '262',
                                 MNC  => '02',
                                 IMSI => '262020123456789',
                                 SNR  => '5558624711',
                                 LAC  => '9755513',
                                 CI   => '75321',
                               },
                  '/test_2' => {
                                 MCC => '262',
                                 MNC => '07',
                               },
                  '/test_3' => {
                                 MCC => '262',
                                 MNC => '08',
                               },
                  '/test_4' => {
                                 MCC => '262',
                                 MNC => '11',
                               }
                );

my $modem1 = Net::Radio::Modem->new( 'Static', \%test_data );
isa_ok( $modem1->{impl}, "Net::Radio::Modem::Adapter::Static" );
my $modem2 = Net::Radio::Modem->new( 'Static', %test_data );
isa_ok( $modem2->{impl}, "Net::Radio::Modem::Adapter::Static" );

my @modem1_devs = $modem1->get_modems();
cmp_bag( \@modem1_devs, [qw(/test_0 /test_1 /test_2 /test_3 /test_4)], "Get entire mocked modem list" );
my @modem2_devs = $modem2->get_modems();
cmp_bag( \@modem2_devs, \@modem1_devs, "Get entire mocked modem list"  );

is( $modem1->get_modem_property('/test_0', 'MobileCountryCode'), "364", "Expand MCC correctly in initialisation");
is( $modem1->get_modem_property('/test_0', 'MCC'), "364", "Expand MCC correctly in property fetching");
is( $modem1->get_modem_property('/test_0', 'MobileNetworkCode'), "390", "Expand MNC correctly in initialisation");
is( $modem1->get_modem_property('/test_0', 'MNC'), "390", "Expand MNC correctly in property fetching");
is( $modem1->get_modem_property('/test_0', 'InternationalMobileSubscriberIdentity'), "364390123456789", "Expand IMSI correctly in initialisation");
is( $modem1->get_modem_property('/test_0', 'IMSI'), "364390123456789", "Expand IMSI correctly in property fetching");
is( $modem1->get_modem_property('/test_0', 'SerialNumber'), "4443794711", "Expand SNR correctly in initialisation");
is( $modem1->get_modem_property('/test_0', 'SNR'), "4443794711", "Expand SNR correctly in property fetching");
is( $modem1->get_modem_property('/test_0', 'LocationAreaCode'), "7532", "Expand LAC correctly in initialisation");
is( $modem1->get_modem_property('/test_0', 'LAC'), "7532", "Expand LAC correctly in property fetching");
is( $modem1->get_modem_property('/test_0', 'CellId'), "4711", "Expand CI correctly in initialisation");
is( $modem1->get_modem_property('/test_0', 'CI'), "4711", "Expand CI correctly in property fetching");

my @bahama_modems1 =
  grep { $modem1->get_modem_property( $_, 'MobileCountryCode' ) == 364 } @modem1_devs;
cmp_bag( \@bahama_modems1, [qw(/test_0)], "Find modem device with Bahamas SIM" );
my @bahama_modems2 =
  grep { $modem2->get_modem_property( $_, 'MobileCountryCode' ) == 364 } @modem2_devs;
cmp_bag( \@bahama_modems2, \@bahama_modems1, "Find modem device with Bahamas SIM" );

my @ger_o2_mncs = qw(07 08 11);
my @o2_modems1 = grep {
    $modem1->get_modem_property( $_, 'MCC' ) == 262    # Germany
      and ($modem1->get_modem_property( $_, 'MNC' ) ~~ @ger_o2_mncs)
} @modem1_devs;
cmp_bag( \@o2_modems1, [qw(/test_2 /test_3 /test_4)], "Find devices with German O2 SIMs" );
my @o2_modems2 = grep {
    $modem1->get_modem_property( $_, 'MCC' ) == 262    # Germany
      and ($modem1->get_modem_property( $_, 'MNC' ) ~~ @ger_o2_mncs)
} @modem2_devs;
cmp_bag( \@o2_modems2, \@o2_modems1, "Find devices with German O2 SIMs" );

my $null_modem = Net::Radio::Modem->new("Null");
isa_ok( $null_modem->{impl}, "Net::Radio::Modem::Adapter::Null" );
my @no_modems = $null_modem->get_modems();
cmp_bag( \@no_modems, [], "Get empty modem list" );

done_testing();
