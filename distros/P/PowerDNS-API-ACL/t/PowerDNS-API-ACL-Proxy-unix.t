#!/usr/bin/env perl
use 5.014;
use strict;
use warnings FATAL => 'all';
use re '/aasx';

# Both import by being loaded, which ProhibitUnusedImports cannot see.
use Test2::V1 -i;                 ## no critic (ProhibitUnusedImports)
use Test2::Plugin::NoWarnings;    ## no critic (ProhibitUnusedImports)
use FindBin::libs;
use File::Temp       qw{tempdir};
use IO::Socket::UNIX ();
use Socket           qw{SOCK_STREAM};
use POSIX            ();
use Time::HiRes      qw{alarm};
use Plack::Test;
use HTTP::Request::Common qw{GET};
use Cpanel::JSON::XS      ();

use PowerDNS::API::ACL::Proxy;

# The proxy with nothing mocked, against a PowerDNS faked on a unix socket.
# The unit tests mock HTTP::Tiny, so only this one reaches HTTP::Tiny::UNIX.
skip_all('An integration test: set RELEASE_TESTING to run it') unless $ENV{RELEASE_TESTING};

{

    package Fake::Store;
    sub new              { my ( $class, %grants_of ) = @_; return bless {%grants_of}, $class }
    sub grants_for_token { my ( $self,  $token )     = @_; return @{ $self->{$token} // [] } }
}

my $JSON     = Cpanel::JSON::XS->new->utf8->canonical;
my $ZONE     = 'lab.test.test.';
my $PATH     = "/api/v1/servers/localhost/zones/$ZONE";
my $REQUESTS = 2;

my $dir    = tempdir( CLEANUP => 1 );
my $socket = "$dir/api.sock";
my $listen = IO::Socket::UNIX->new( Local => $socket, Type => SOCK_STREAM, Listen => 5 ) or die "listen on $socket: $!";

# Answers each request with the zone, and the key it was sent as a header, so
# the parent can see that the real key went upstream.
my $server = fork() // die "fork: $!";
if ( !$server ) {

    # A proxy that never connects leaves accept waiting, so the child gives up.
    alarm(10);
    foreach ( 1 .. $REQUESTS ) {
        my $client = $listen->accept or last;
        my ( $key, $line ) = (q{});
        while ( defined( $line = <$client> ) ) {
            $key = $1 if $line =~ m/\AX-API-Key:[ ]*(\S+)/i;
            last if $line =~ m/\A\r?\n\z/;
        }
        my $body = $JSON->encode( { name => $ZONE, rrsets => [ { name => "web.$ZONE", type => 'A' }, { name => "db.$ZONE", type => 'A' } ], key => $key } );
        print {$client} "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: " . length($body) . "\r\nConnection: close\r\n\r\n$body";
        close($client) or warn "close: $!\n";
    }
    POSIX::_exit(0);
}
close($listen) or die "close: $!\n";

my $store = Fake::Store->new( web => [ { zone => $ZONE, name => "web.$ZONE", types => ['A'], access => 'read' } ] );
my $app   = Plack::Test->create( PowerDNS::API::ACL::Proxy->new( store => $store, api_key => 'the-real-key', upstream => $socket, timeout => 5 )->to_app );

foreach my $n ( 1 .. $REQUESTS ) {
    my $res = $app->request( GET $PATH, 'X-API-Key' => 'web' );
    is( $res->code, 200, "request $n reaches PowerDNS over the socket" ) or diag $res->content;
    my $zone = eval { $JSON->decode( $res->content ) } // {};
    is( $zone->{key},                                      'the-real-key', 'with the real key' );
    is( [ map { $_->{name} } @{ $zone->{rrsets} // [] } ], ["web.$ZONE"],  'and comes back filtered' );
}

waitpid( $server, 0 );
done_testing;
