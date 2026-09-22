use v5.36;
use warnings FATAL => 'all';
use re '/aa';

=head1 NAME

t/SolusVM-Client-Live.t - SolusVM::Client against a real management node

=cut

use Test2::V1 -i;

use FindBin::libs;
use SolusVM::Client ();

# An acceptance test: no mocks, a real management node, and therefore off by
# default.  Point it at one with
#
#   AUTHOR_TESTING=1 SOLUSVM_HOST=... SOLUSVM_USER=... SOLUSVM_PASS=... prove -lmv t/SolusVM-Client-Live.t
#
# or, on a node whose accounts come from an identity provider and so have no
# password to give, with a token made in the panel:
#
#   AUTHOR_TESTING=1 SOLUSVM_HOST=... SOLUSVM_TOKEN=... prove -lmv t/SolusVM-Client-Live.t
#
# Everything above is read-only.  Creating and destroying a server costs real
# resources on somebody's node, so it takes saying so again:
#
#   SOLUSVM_LIVE_CREATE=1
#
skip_all('acceptance test; set AUTHOR_TESTING=1 to run it') unless $ENV{AUTHOR_TESTING};
skip_all('SOLUSVM_HOST, and then either SOLUSVM_TOKEN or SOLUSVM_USER and SOLUSVM_PASS, say which node to run it against and how to get in')
  unless $ENV{SOLUSVM_HOST} && ( $ENV{SOLUSVM_TOKEN} || ( $ENV{SOLUSVM_USER} && $ENV{SOLUSVM_PASS} ) );

my $solus = SolusVM::Client->new(
    host => $ENV{SOLUSVM_HOST},
    $ENV{SOLUSVM_TOKEN}
    ? ( token => $ENV{SOLUSVM_TOKEN} )
    : ( email => $ENV{SOLUSVM_USER}, password => $ENV{SOLUSVM_PASS} ),
);

my $CREATED;
my $PROJECT;

subtest 'getting in' => sub {
    if ( $ENV{SOLUSVM_TOKEN} ) {
        my $account = $solus->get_user_info()->{data};
        ok( $account->{email}, 'the token is good enough to be told whose it is' );
        note( sprintf 'token belongs to %s, who is %s', $account->{email}, join q{, }, map { $_->{name} } @{ $account->{roles} // [] } );
    }
    else {
        my $credentials = $solus->login();

        ok( $credentials->{access_token}, 'the node gave us a token' );
        ok( $credentials->{expires_at},   'and said when it stops working' );
        note("token expires $credentials->{expires_at}");

        is( $solus->token(), $credentials->{access_token}, 'and it is the one that gets used' );
    }

    $PROJECT = $ENV{SOLUSVM_PROJECT} // $solus->get_list_of_projects()->{data}[0]{id};
    ok( $PROJECT, "there is a project ($PROJECT) to work in" );
};

subtest 'listings' => sub {
    foreach my $listing (qw{get_list_of_projects get_list_of_locations get_list_of_os_images get_list_of_applications}) {
        my $answer = $solus->$listing();
        ok( ref $answer->{data} eq 'ARRAY', "$listing answered with a list" );
        note( sprintf '%-26s %d of %s', $listing, scalar @{ $answer->{data} }, ( $solus->last_meta // {} )->{total} // 'no count given' );
    }

    # What a CLIENT can see is its projects' -- /servers and /plans are the
    # whole node, and answer 403 to anybody who is not running it.  So the
    # listings that matter are asked for by project, and this is the difference
    # between a token that can provision and one that can administer.
    foreach my $listing (qw{get_list_of_project_servers get_list_of_project_plans get_list_of_project_ssh_keys}) {
        my $answer = $solus->$listing( id => $PROJECT );
        ok( ref $answer->{data} eq 'ARRAY', "$listing answered with a list" );
        note( sprintf '%-26s %d of %s', $listing, scalar @{ $answer->{data} }, ( $solus->last_meta // {} )->{total} // 'no count given' );
    }
};

subtest 'paginate' => sub {
    my @plans = $solus->paginate( 'get_list_of_project_plans', id => $PROJECT );
    my $meta  = $solus->last_meta;

    is( scalar @plans, $meta->{total}, 'walking the pages gets as many plans as the node counted' );
    ok( $meta->{last_page} > 1, 'and it took more than one page, so the walking was the thing being tested' );
    note( sprintf 'walked %d plans over %d pages of %d', scalar @plans, $meta->{last_page}, $meta->{per_page} );
};

subtest 'a failure from the node itself' => sub {
    like(
        dies { $solus->get_an_existing_server( id => 999_999_999 ) },
        qr/failed: 4\d\d/,
        'asking after a server that is not there fails the way this client says failures look',
    );
    is( $solus->last_response->{status}, in_set( 403, 404 ), 'and the response is there to be looked at' );
};

subtest 'create and destroy a server' => sub {
    skip_all('set SOLUSVM_LIVE_CREATE=1 to spend real resources') unless $ENV{SOLUSVM_LIVE_CREATE};

    my $location = $ENV{SOLUSVM_LOCATION} // $solus->get_list_of_locations()->{data}[0]{id};
    my $os       = $ENV{SOLUSVM_OS}       // _an_os_image();
    my $plan     = $ENV{SOLUSVM_PLAN}     // _smallest_plan();
    my $name     = "solusvm-client-$$";

    ok( $location && $os && $plan, "there is a location ($location), an os image ($os) and a plan ($plan) to build with" );

    # The project endpoint's body is not the node-wide one's: plan_id rather
    # than plan, and so on down.  Asking the catalog for both create operations
    # is the difference, spelled out.
    my $made = $solus->create_a_new_project_server(
        id                  => $PROJECT,
        name                => $name,
        location_id         => $location,
        os_image_version_id => $os,
        plan_id             => $plan,
        user_data           => "#cloud-config\nruncmd:\n  - [ true ]\n",
    );

    $CREATED = $made->{data}{id};
    ok( $CREATED, "the node built server $CREATED" );

    my $server = _wait_for( $CREATED, 'started', 900 );
    is( $server->{status}, 'started', 'and it came up' );
    note( sprintf 'server %s is %s at %s', $CREATED, $server->{status}, join q{, }, map { $_->{ip} } @{ $server->{ips} // [] } );

    $solus->delete_server( id => $CREATED );
    ok( _wait_for_gone( $CREATED, 600 ), 'and it went away again when asked' );
    undef $CREATED;
};

# The cheapest thing the node will build, which is what a test that is going to
# throw it away immediately should be asking for.
sub _an_os_image {
    my ($image) = grep { $_->{name} =~ m/debian/i } @{ $solus->get_list_of_os_images()->{data} };
    ($image) //= $solus->get_list_of_os_images()->{data}[0];
    return $image->{versions}[0]{id};
}

sub _smallest_plan {
    my @plans = sort { ( $a->{params}{ram} // 0 ) <=> ( $b->{params}{ram} // 0 ) } $solus->paginate( 'get_list_of_project_plans', id => $PROJECT );
    return $plans[0]{id};
}

sub _wait_for ( $id, $wanted, $timeout ) {
    my $deadline = time + $timeout;
    my $server;

    while ( time < $deadline ) {
        $server = $solus->get_an_existing_server( id => $id )->{data};
        return $server if ( $server->{status} // q{} ) eq $wanted;
        sleep 10;
    }

    return $server;
}

sub _wait_for_gone ( $id, $timeout ) {
    my $deadline = time + $timeout;

    while ( time < $deadline ) {
        return 1 unless eval { $solus->get_an_existing_server( id => $id ); 1 };
        sleep 10;
    }

    return 0;
}

# A test that died between building a server and deleting it has left one
# running on somebody's node.  This is the only place that can still notice.
END {
    return unless $CREATED && $solus;
    diag("cleaning up server $CREATED, which the test did not get to");
    eval { $solus->delete_server( id => $CREATED ); 1 } or diag("could not delete server $CREATED: $@");
}

done_testing();
