package t::Client;

use Data::Dumper;

use HTTP::Status;
use LWP::UserAgent;
use LWP::ConnCache;
use HTTP::Request;

sub my_sleep {
    my( $s ) = @_;
    ::diag( "$$: Sleep $s..." );
    sleep $s;
    ::diag( "$$: continue" );
}
*::my_sleep = \&my_sleep;


sub tests 
{
    my( $PORT, $KA_MAX, $S ) = @_;

    my_sleep $S;

    my $MAX = 2;
    my @UA;
    my $CC = LWP::ConnCache->new();

    #####
    ## First request
    my @C;
    my @CID;
    foreach my $n ( 0..$MAX ) {

        $UA[$n] = LWP::UserAgent->new;
        $UA[$n]->conn_cache( $CC );
        my $req=HTTP::Request->new(GET => "http://localhost:$PORT/");
    #    $req->protocol( 'HTTP/1.1' );
        my $resp=$UA[$n]->request($req);

        push @C, $CC->get_connections;
        push @CID, $resp->header( 'X-CID' );

        is_index( $resp );
    }

    my_sleep 1;
    $CC->prune;
    ::is( $CC->get_connections( 'http' ), 1, "They all shared the same connection" );
    ::is_deeply( \@C, [ ( $C[0] ) x ($MAX+1) ], " ... and same protocol object" );
    ::is_deeply( \@CID, [ ( $CID[0] ) x ($MAX+1) ], " ... and same connection ID" );

    #####
    ## second request
    foreach my $ua ( @UA ) {

        my $req=HTTP::Request->new( GET => "http://localhost:$PORT/honk/" );
        my $resp=$ua->request( $req );

        my @new = $CC->get_connections;
        if( @new ) {
            push @C, @new;
        }
        else {              # after KA_MAX, there will be no open connections
            push @C, 0;     # marker for the test cases
        }
        push @CID, $resp->header( 'X-CID' );

        is_honk( $resp );
    }

    my_sleep 1;
    $CC->prune;
    ::is( $CC->get_connections( 'http' ), 1, "They all shared the same connection" );
    my $want = [ ( $CID[0] ) x ($KA_MAX+1),
                 ( $CID[$KA_MAX+1] ) x ( @CID-($KA_MAX+1) ) ];
    ::is_deeply( \@CID, $want, " ... and same connection ID" )
        or die Dumper { CID=>\@CID, want=>$want };

    $want = [ ( $C[0] ) x ($KA_MAX), 0,
                 ( $C[$KA_MAX+1] ) x ( @C-($KA_MAX+1) ) ];
    ::is_deeply( \@C, $want, " ... and shared protocol objects" )
        or die Dumper { CID=>\@CID, C=>\@C, want=>$want };

    #####
    ## Let everything timeout
    my $sharedC = $C[-1];
    my $sharedCID = $CID[-1];

    my_sleep $S+1;

    $CC->prune;
    ::is( $CC->get_connections( 'http' ), 0, "They all timed out" )
        or die "MAKE IT SO";

    #####
    ## third request
    @C = ();
    @CID = ();
    foreach my $ua ( @UA ) {

        my $req=HTTP::Request->new( GET => "http://localhost:$PORT/honk/" );
        my $resp=$ua->request( $req );

        push @C, $CC->get_connections;
        push @CID, $resp->header( 'X-CID' );

        is_honk( $resp );
    }

    my_sleep 1;
    $CC->prune;
    ::is( $CC->get_connections( 'http' ), 1, "They all shared the same connection" );
    ::is_deeply( \@C, [ ( $C[0] ) x (0+@C) ], " ... and same protocol object" );
    ::isnt( $C[0], $sharedC, " ... but it is new" );
    ::is_deeply( \@CID, [ ( $CID[0] ) x ($MAX+1) ], " ... and same connection ID" );
    ::isnt( $CID[0], $sharedCID, " ... but it is new" );

    # use Data::Dumper;
    # warn Dumper \@C;

    ##### Fourth request, this will create too many connections
    @C = ();
    foreach my $n ( 0 .. (3*$MAX) ) {

        unless( $UA[$n] ) {
            $UA[$n] = LWP::UserAgent->new;
            $UA[$n]->conn_cache( $CC );
        }
        my $req=HTTP::Request->new(GET => "http://localhost:$PORT/bonk/zip.html");
        my $resp=$UA[$n]->request($req);

        push @C, $CC->get_connections;

        is_bonk2( $resp );
    }

    # Note: The first request doesn't result in a connection object
    # 1-5 do though

    $CC->prune;
    ::is( $CC->get_connections( 'http' ), 1, "There are 1 active connection" );
    ::is_deeply( \@C, [ ( ( $C[0] ) x 3), ( ( $C[3] ) x 2) ], 
                " ... but 3 were used, 3 conns max" );

    # use Data::Dumper;
    # warn Dumper \@C;
}

############################################################
sub is_index
{
    my( $resp ) = @_;
    ::ok($resp->is_success, "got index") or die "resp=", Dumper $resp;
    my $content=$resp->content;
    ::ok($content =~ /this is top/, "got top index");
}

sub is_honk
{
    my( $resp ) = @_;
    ::ok($resp->is_success, "got honk") or die "resp=", Dumper $resp;
    my $content=$resp->content;
    ::ok($content =~ /this is honk/, "got honk");
}

sub is_bonk2
{
    my( $resp ) = @_;
    ::ok($resp->is_success, "got bonk2") or die "resp=", Dumper $resp;
    my $content=$resp->content;
    ::ok($content =~ /This, my friend/, "got bonk2") or die "content=$content";
}

1;
