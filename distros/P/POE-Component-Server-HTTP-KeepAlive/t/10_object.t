#!/usr/bin/perl -w

use strict;
use warnings;
use HTTP::Response;
use HTTP::Request;
use Storable qw( dclone );
use Data::Dumper;

use Test::More ( tests => 36 );

use POE::Component::Server::HTTP::KeepAlive;

# ->new needs a session...
my $ka = bless { max => 10, total_max => 100, timeout => 60, connections=>{} }, 
                'POE::Component::Server::HTTP::KeepAlive';

my $resp = HTTP::Response->new( 200 );

# Testing ->connection
is( $ka->connection( $resp, 'Close' ), 0, "Didn't find close keyword" );
is( $ka->connection( $resp, 'close' ), 0, "Didn't find close keyword" );
$resp->header( Connection => 'close' );
is( $ka->connection( $resp, 'Close' ), 1, "Found Close keyword" );
is( $ka->connection( $resp, 'close' ), 1, "Found close keyword" );
is( $ka->connection( $resp, 'TE' ), 0, "Didn't find TE" );
is( $ka->connection( $resp, 'te' ), 0, "Didn't find te" );
$resp->header( Connection => 'TE,close' );
is( $ka->connection( $resp, 'Close' ), 1, "Found Close keyword" );
is( $ka->connection( $resp, 'close' ), 1, "Found close keyword" );
is( $ka->connection( $resp, 'TE' ), 1, "Found TE" );
is( $ka->connection( $resp, 'tE' ), 1, "Found tE" );
is( $ka->connection( $resp, 'Keep-Alive' ), 0, "Didn't find Keep-Alive" );
is( $ka->connection( $resp, 'keep-alive' ), 0, "Didn't find Keep-Alive" );
$resp->header( Connection => 'TE,close,Keep-Alive' );
is( $ka->connection( $resp, 'Close' ), 1, "Found Close keyword" );
is( $ka->connection( $resp, 'close' ), 1, "Found close keyword" );
is( $ka->connection( $resp, 'TE' ), 1, "Found TE" );
is( $ka->connection( $resp, 'tE' ), 1, "Found tE" );
is( $ka->connection( $resp, 'Keep-Alive' ), 1, "Found Keep-Alive" );
is( $ka->connection( $resp, 'keep-alive' ), 1, "Found keep-alive" );


# Testing ->timeout
is( $ka->timeout( $resp ), 60, "Default timeout" );
$resp->header( 'Keep-Alive' => '30' );
is( $ka->timeout( $resp ), 30, "HTTP/1.0 Keep-Alive override" );
$resp->header( 'Keep-Alive' => 'timeout=25, max=3' );
is( $ka->timeout( $resp ), 25, "HTTP/1.1 Keep-Alive override" );
$resp->header( 'Keep-Alive' => 'Other' );
is( $ka->timeout( $resp ), 60, "Default timeout" );

$resp->header( 'Keep-Alive' => '600' );
is( $ka->timeout( $resp ), 60, "HTTP/1.0 Keep-Alive too long" );
$resp->header( 'Keep-Alive' => 'timeout=250, max=3' );
is( $ka->timeout( $resp ), 60, "HTTP/1.1 Keep-Alive too long" );

# Testing ->keep_response
$resp->remove_header( 'Connection' );
my $req = HTTP::Request->new( GET => '/honk.html' );
$req->header( 'Keep-Alive' => 300 );
$req->header( Connection => 'Keep-Alive' );

my $c = {};
$ka->keep_response( $req, $resp, $c );
is( $ka->connection( $resp, 'keep-alive'), 1, "Connection: Keep-Alive" );

$ka->keep_response( $req, $resp, {} );
is( $ka->connection( $resp, 'keep-alive'), 1, "Connection: Keep-Alive" );
is_deeply( [ $resp->header( 'connection' ) =~ /(K)eep-Alive/g ], 
           [ 'K' ], " ... once" );

# Testing ->drop_response
my $hka = $resp->header( 'Keep-Alive' );
ok( ($hka =~ /\bmax=10\b/), "Max=10" );
my $timeout = $ka->timeout( $resp );

$ka->drop_response( $req, $resp, $c );
is( $resp->header( 'Keep-Alive' ), undef, "No Keep-Alive" );
is( $ka->connection( $resp, 'keep-alive'), 0, "Not Connection: Keep-Alive" );
is( $ka->connection( $resp, 'close'), 1, "Connection: close" );
$resp->header( Connection => 'TE' );
$ka->drop_response( $req, $resp, $c );
is( $ka->connection( $resp, 'close'), 1, "Connection: mutter,close" );
$resp->remove_header( 'Connection' );
$ka->drop_response( $req, $resp, $c );
is( $ka->connection( $resp, 'close'), 1, "Connection: close" );

# Testing ->keep + ->drop
my $heap = {};
$ka = bless { heap => $heap, max => 10, total_max => 10, timeout => 60, 
                connections=>{} }, 
                'My::KeepAlive';

$c = bless {  wheel => bless { id=>17 }, 'My::Wheel'  }, 
            'My::Connection';
$heap->{c}{17} = dclone $c;

$ka->keep( $req, $heap->{c}{17} );
is_deeply( [ keys %{ $ka->{connections}} ], [ 17 ], "Kept" );
is( $heap->{c}{17}{keepalives}, 1, "-alive" )
    or die Dumper $heap->{c}{17};

foreach my $n ( 1..10 ) {
    $c->{wheel}{id} = $n;
    $heap->{c}{$n} = dclone $c;
    $ka->keep( $req, $heap->{c}{$n} );
}

foreach my $id ( keys %{ delete $ka->{closed} } ) {
    $ka->drop( $id );
}

# Testing max
$ka->{total_max} = 5;
$c->{wheel}{id} = 42;
$heap->{c}{42} = dclone $c;
$ka->keep( $req, $heap->{c}{42} );

foreach my $id ( keys %{ delete $ka->{closed} } ) {
    $ka->drop( $id );
}

$c = $ka->{connections};
is_deeply( [ sort { $c->{$a}->{N} <=> $c->{$b}->{N} }
                keys %{ $ka->{connections} } ], 
           [ 7..10, 42 ], "5 kept" );



delete $ka->{heap};

############################################################################
package My::KeepAlive;

use strict;
use warnings;

use base qw( POE::Component::Server::HTTP::KeepAlive );

sub timeout { 0 }
sub conn_on_close { $_[0]->{on_close} = [ @_[1..$#_] ] }
sub get_heap { $_[0]->{heap} }
sub conn_close 
{ 
    my( $self, $c, $id ) = @_;
    $id ||= $self->conn_ID( $c );
    $self->{closed}{ $id } ++;
}


############################################################################
package My::Wheel;

use strict;
use warnings;

sub ID { $_[0]->{id} }

############################################################################
package My::Connection;

use strict;
use warnings;

sub ID { $_[0]->{wheel}->ID }

