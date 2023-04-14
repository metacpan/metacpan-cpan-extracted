#!perl
#
# gemini server tests. NOTE this server is mostly to test the
# Net::Gemini client with, probably you may want vger or gmid or really
# anything besides this on a real server(TM)

use strict;
use warnings;
use Test2::V0;
plan 2;

use Net::Gemini::Server;

{
    my $serv = Net::Gemini::Server->new(
        listen => { LocalAddr => '127.0.0.1', LocalPort => 0 } );
    #diag sprintf "listen %d", $serv->port;
    number( $serv->port );
    is( $serv->context, D() );
}

# NOTE " " is a valid domainname per RFC 1035. hence a bunch of spaces
# for that slot and a negative port number. this still might run into
# PORTABILITY problems if some OS accepts such?
like(
    dies {
        Net::Gemini::Server->new(
            listen => {
                LocalAddr => "    ",
                LocalPort => -1,
            }
        )
    },
    qr/server failed/
);
