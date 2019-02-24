#!perl

use strict;
use warnings;

use Test::More tests => 4 * 10;

use File::Spec;
use Sys::HostIP;
use lib '.';
use t::lib::Utils qw/mock_win32_hostip/;

## no critic qw(Subroutines::RequireFinalReturn)
sub test_mock_ipconfig {
    my ( $file, $expected_results, $test_name ) = @_;

    # Mock Windows
    local $Sys::HostIP::IS_WIN = 1;

    my $hostip = mock_win32_hostip($file);

    isa_ok( $hostip, 'Sys::HostIP' );

    is_deeply(
        $hostip->_get_win32_interface_info,
        $expected_results,
        $test_name,
    );
}

test_mock_ipconfig(
    'ipconfig-2k.txt',
    { 'Local Area Connection' => '169.254.109.232' },
    'Correct Win2K interface',
);

test_mock_ipconfig(
    'ipconfig-xp.txt',
    { 'Local Area Connection' => '0.0.0.0' },
    'Correct WinXP interface',
);

test_mock_ipconfig(
    'ipconfig-win7.txt',
    {
        'Local Area Connection'   => '192.168.0.10',
        'Local Area Connection 2' => '192.168.1.20',
    },
    'Correct Win7 interface',
);

test_mock_ipconfig(
    'ipconfig-win7-empty-name.txt',
    {
        '' => '192.168.1.101',
    },
    'Win7 interface, empty name',
    );

test_mock_ipconfig(
    'ipconfig-win10.txt',
    {
        'Ethernet' => '192.168.1.100',
    },
    'Correct Win10 interface',
    );

test_mock_ipconfig(
    'ipconfig-win2008-sv_SE.txt',
    {
        'Anslutning till lokalt n�tverk' => '192.168.40.241',
    },
    'Correct Windows Server 2008 interface in Swedish locale',
    );

test_mock_ipconfig(
    'ipconfig-win7-de_DE.txt',
    {
        'LAN-Verbindung' => '10.0.2.15',
    },
    'Correct Windows 7 interface in German locale',
    );

test_mock_ipconfig(
    'ipconfig-win7-fr_FR.txt',
    {
        'LAN-Verbindung' => '192.168.2.118',
        'VirtualBox Host-Only Network' => '192.168.56.1',
    },
    'Correct Windows 7 interface in French locale',
    );

test_mock_ipconfig(
    'ipconfig-win7-it_IT.txt',
    {
        'LAN-Verbindung' => '192.168.2.118',
        'VirtualBox Host-Only Network' => '192.168.56.1',
    },
    'Correct Windows 7 interface in Italian locale',
    );

test_mock_ipconfig(
    'ipconfig-win7-fi_FI.txt',
    {
        'LAN-Verbindung' => '192.168.2.118',
        'VirtualBox Host-Only Network' => '192.168.56.1',
    },
    'Correct Windows 7 interface in Finnish locale',
    );
