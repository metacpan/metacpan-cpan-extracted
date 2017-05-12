#!perl

use strict;

use Net::ILO;
use Test::More;

my @commands = qw(
    get_embedded_health     get_global_settings     get_fw_version
    get_host_data           get_network_settings    power_consumption
    power_on                power_off               reset
    uid_on                  uid_off                 uid_status
);

plan tests => scalar @commands * 2 + 1;

# _generate_cmd requires that username and password are set

my $ilo = Net::ILO->new({
    username => 'test',
    password => 'test',
    version  => 2,
});

foreach my $command (@commands) {

    my $xml;

    # _generate_cmd considers it a fatal error if you ask for a command
    # which doesn't exist

    eval { $xml = $ilo->_generate_cmd($command); };

    ok( !$@, "Command '$command' exists");

    # iLO requires a syntax which is not valid XML so we need to add
    # a closing tag at the end for purposes of this test only

    $xml .= '</LOCFG>';

    my $serialized = $ilo->_serialize($xml);

    ok( $serialized, "Command '$command' is valid XML" );

}

# ask for a command which doesn't exist

my $xml;

eval { $xml = $ilo->_generate_cmd('create_rainbow'); } ;

ok( $@ =~ /Internal error:/, 'Requesting invalid command throws exception' );

