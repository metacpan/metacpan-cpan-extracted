#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;

use t::Test;
use Net::ClientServer;

my ( $platform );

my $port = t::Test->find_port;
plan skip_all => "Unable to find port" unless $port;
plan skip_all => "Unable to fork" unless t::Test->can_fork;
plan 'no_plan';

my $message = 'Apple';

$platform = Net::ClientServer->new( port => $port,
    daemon => 0,
    start => sub {
        $message = 'Xyzzy';
    },
    serve => sub {
        my $client = shift;
        $client->print( $message, "\n" );
        $client->close;
        CORE::exit( 0 );
    },
);

if ( fork ) {
    # Parent
    sleep 1;
    my $socket = $platform->client_socket;
    my $message = join '', <$socket>;
    is ( $message, "Xyzzy\n", "\$message is \"Xyzzy\\n\"" );
}
else {
    # Child
    $platform->start;
}
