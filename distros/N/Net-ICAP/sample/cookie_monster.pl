#!/usr/bin/perl

use strict;
use warnings;

use Net::ICAP::Server;
use Net::ICAP::Common qw(:req :resp);
use Paranoid::Debug;

#PDEBUG = 20;

sub cookie_monster {
    my $client   = shift;
    my $request  = shift;
    my $response = new Net::ICAP::Response;
    my $header =
        $request->method eq ICAP_REQMOD ? $request->reqhdr : $request->reshdr;

    if ( $header =~ /\r\n(?:(?:Set-)?Cookie\d*|ETag):/smi ) {

        # Unfold all header lines
        $header =~ s/\r\n\s+/ /smg;

        # Cookie Monster eat cookie... <smack>
        $header =~ s/\r\n(?:(?:Set-)?Cookie\d*|ETag):[^\r]+//smg;

        # Save changes
        $response->status(ICAP_OK);
        $response->body( $request->body );
        $request->method eq ICAP_REQMOD
            ? $response->reqhdr($header)
            : $response->reshdr($header);

    } else {
        $response->status(ICAP_NO_MOD_NEEDED);
    }

    return $response;
}

sub my_logger {
    my $client   = shift;
    my $request  = shift;
    my $response = shift;
    my ( $line, $header, $url, %headers );

    # Assemble the URL from the HTTP header
    $header = $request->reqhdr;
    ($url)  = ($header =~ /^\S+\s+(\S+)/smi);

    # Create the log line
    $line = sprintf( "%s %s: %s %s %s\n",
        ( scalar localtime ),
        $client->peerhost, $request->method, $response->status, $url );

    warn $line;
}

my $server = Net::ICAP::Server->new(
    max_requests => 50,
    max_children => 50,
    options_ttl  => 3600,
    services     => {
        '/outbound' => ICAP_REQMOD,
        '/inbound'  => ICAP_RESPMOD,
        },
    reqmod  => \&cookie_monster,
    respmod => \&cookie_monster,
    logger => \&my_logger,
    );

$server->run;
