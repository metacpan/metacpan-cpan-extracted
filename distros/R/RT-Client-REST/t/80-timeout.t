#!perl
# vim:ft=perl:
#
# This script tests whether timeout actually works.

use strict;
use warnings;

use Test::More;

use Try::Tiny;
use IO::Socket;
use RT::Client::REST;
use LWP::UserAgent;

plan( skip_all => "LWP::UserAgent 6.04 does not know how to time out, "
      . "see RT #81799" )
  if $LWP::UserAgent::VERSION eq '6.04';

my $server = IO::Socket::INET->new(
    Type   => SOCK_STREAM,
    Reuse  => 1,
    Listen => 10,
) or die "Could not set up TCP server: $@";

my $port = $server->sockport;

my $pid = fork;    # Fork
die "Could not fork: $!" unless defined $pid;

if ( 0 == $pid ) {    # Child
    my $buf;
    my $client = $server->accept;
    1 while ( $client->read( $buf, 1024 ) );
    exit;
}

plan tests => 8;      # Parent
for my $timeout ( 1, 2, 5, 10 ) {
    my $rt = RT::Client::REST->new(
        server  => "http://127.0.0.1:$port",
        timeout => $timeout,
    );
    my $t1 = time;
    my ( $e, $t2 );
    try {
        $rt->login(qw(username a password b));
    }
    catch {
        die $_ unless blessed $_ && $_->can('rethrow');
        if ( $_->isa('Exception::Class::Base') ) {
            $t2 = time;
            $e  = $_;
        }
        else {
            $_->rethrow;
        }
    };

    isa_ok( $e, 'RT::Client::REST::RequestTimedOutException' );
    ok( $t2 - $t1 >= $timeout, "Timed out after $timeout seconds" );
}

