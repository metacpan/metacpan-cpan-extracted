#!perl

use strict;
use warnings;

use lib '.';
use Test::More 'tests' => 4;
use Sys::HostIP qw/ip/;
use Capture::Tiny qw/capture/;

# check unavailable interface on Windows
{
    # Mock Windows
    local $Sys::HostIP::IS_WIN = 1;
    {
        ## no critic qw(TestingAndDebugging::ProhibitNoWarnings)
        no warnings qw/redefine once/;
        *Sys::HostIP::_get_win32_interface_info = sub {
            return {};
        };
    }
    my ($stdout, $stderr, @result) = capture { ip() };

    like(
        $stderr,
        qr/Unable to detect interface information!/,
        "Inform user if interface info not detectable"
    );
    is( $result[0], '', "Empty ip info returned" );
}

# check unavailable interface on *nix
{
    {
        ## no critic qw(TestingAndDebugging::ProhibitNoWarnings)
        no warnings qw/redefine once/;
        *Sys::HostIP::_get_unix_interface_info = sub {
            return {};
        };
    }
    my ($stdout, $stderr, @result) = capture { ip() };

    like(
        $stderr,
        qr/Unable to detect interface information!/,
        "Inform user if interface info not detectable"
    );
    is( $result[0], '', "Empty ip info returned" );
}
