#!perl

use strict;
use warnings;

use Test::More tests => 6;
use Test::MockModule;
use Test::Trap qw/ :on_fail(diag_all) /;
use Monit::HTTP ':constants';

my $xml = q{<?xml version="1.0" encoding="ISO-8859-1"?>
<monit>
    <server>
        <incarnation>1249406340</incarnation>
        <version>4.8.1</version>
        <uptime>941058</uptime>
        <httpd>
            <address></address>
            <port>2812</port>
            <ssl>0</ssl>
        </httpd>
    </server>
    <service type="3">
        <collected>1250347245</collected>
        <name>ushare</name>
        <status>0</status>
        <monitor>1</monitor>
        <group></group>
        <pid>6513</pid>
        <ppid>1</ppid>
        <uptime>2204</uptime>
        <children>0</children>
        <memory>
            <kilobyte>4892</kilobyte>
            <kilobytetotal>4892</kilobytetotal>
            <percent>1.0</percent>
            <percenttotal>1.0</percenttotal>
        </memory>
        <cpu>
            <percent>1.8</percent>
            <percenttotal>1.8</percenttotal>
        </cpu>
    </service>
    <service type="5">
        <collected>1250347245</collected>
        <name>localhost</name>
        <status>0</status>
        <monitor>1</monitor>
        <group></group>
        <load>
            <avg01>0.04</avg01>
            <avg05>0.01</avg05>
            <avg15>0.00</avg15>
        </load>
        <cpu>
            <user>0.7</user>
            <system>1.2</system>
            <wait>0.0</wait>
        </cpu>
        <memory>
            <kilobyte>46052</kilobyte>
            <percent>9.5</percent>
        </memory>
    </service>
</monit>
};

my $http = Test::MockModule->new('HTTP::Tiny');
$http->mock(
    get => sub {
        return { success => 1, content => $xml };
    }
);
my $hd = Monit::HTTP->new();

my @services = trap {
    $hd->get_services;
};
is( $trap->die, undef, 'get_services musnt die' );

SKIP: {
    skip 5, 'Monit object didnt provide services' unless @services;

    is( $hd->_get_xml, $xml, 'Internal XML should match what we fed it' );

    is( $services[0], 'ushare',    'should be: ushare' );
    is( $services[1], 'localhost', 'should be: localhost' );

    my $status = $hd->service_status( $services[0] );
    is_deeply(
        $status,
        {
            'pid'      => '6513',
            'children' => '0',
            'ppid'     => '1',
            'host'     => 'localhost',
            'cpu'      => {
                'percent'      => '1.8',
                'percenttotal' => '1.8'
            },
            'group'   => '',
            'monitor' => '1',
            'uptime'  => '2204',
            'status'  => '0',
            'name'    => 'ushare',
            'type'    => '3',
            'memory'  => {
                'percenttotal'  => '1.0',
                'kilobyte'      => '4892',
                'percent'       => '1.0',
                'kilobytetotal' => '4892'
            }
        },
        "$services[0] status is correct"
    );

    $status = $hd->service_status( $services[1] );
    is_deeply(
        $status,
        {
            'monitor' => '1',
            'type'    => '5',
            'host'    => 'localhost',
            'group'   => '',
            'name'    => 'localhost',
            'load'    => {
                'avg01' => '0.04',
                'avg05' => '0.01',
                'avg15' => '0.00'
            },
            'status' => '0',
            'memory' => {
                'percent'  => '9.5',
                'kilobyte' => '46052'
            }
        },
        "$services[1] status is correct"
    );

}

