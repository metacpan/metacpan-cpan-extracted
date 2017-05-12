use Test::More tests => 17;

BEGIN {
    use_ok('RDF::Sesame');
    use_ok('URI');
}

#####  try a simple connection ######

SKIP: {
    skip 'SESAME_URI environment not set', 15  unless $ENV{SESAME_URI};
    skip 'SESAME_REPO environment not set', 15 unless $ENV{SESAME_REPO};

    my $uri = $ENV{SESAME_URI};

    # try connecting anonymously
    # this won't actually communicate with the server
    my $uri_o = URI->new($uri);
    $uri_o->userinfo('');
    my $conn = RDF::Sesame->connect(uri => "$uri_o");
    isa_ok($conn, 'RDF::Sesame::Connection', 'anonymous connection');
    # we can't check for repositories because there may
    # not be any public ones

    # try to fail a connection
    $uri_o->userinfo('not a username');
    $conn = RDF::Sesame->connect(uri => "$uri_o");
    is($conn, '', 'failing connect');

    # connect to a non-existent server in several
    # ways.  If no authentication information is given,
    # connect() doesn't even communicate with the server
    $conn = RDF::Sesame->connect('example.com');
    isa_ok($conn, 'RDF::Sesame::Connection', 'host alone');
    $conn = RDF::Sesame->connect(
        host=>'example.com:8080',
        timeout=>1,
    );
    isa_ok($conn, 'RDF::Sesame::Connection', 'host and port');

    # use one of the non-existent server connections to
    # run a command to make sure that failures are handled
    # correctly.
    my @repos = $conn->repositories;
    cmp_ok(scalar @repos, '==', 0, 'repositories on false server');

    # make believe we're logged in to make sure network errors
    # are handled on disconnect
    $conn->{authed} = 1;
    $conn->disconnect();

    # now connect for real
    $conn = RDF::Sesame->connect(uri => $uri);

    isa_ok($conn, 'RDF::Sesame::Connection', 'authenticated connection');
    die "No connection: $RDF::Sesame::errstr\n" unless defined($conn);

    # repositories() in scalar context is intentionally broken
    ok(!defined scalar $conn->repositories, 'scalar repositories() undef');

    # look for repos to make sure the connection is good
    @repos = sort $conn->repositories;
    ok(@repos, 'repository list not empty');

    # list the repositories again to check caching
    my @repos2 = sort $conn->repositories;
    is_deeply( \@repos, \@repos2, 'repositories cache works');

    # refresh the repositories cache
    @repos2 = sort $conn->repositories(1);
    is_deeply( \@repos, \@repos2, 'repositories refresh works');

    # open a repository
    my $repo = $conn->open($ENV{SESAME_REPO});
    isa_ok($repo, 'RDF::Sesame::Repository', "repository [$ENV{SESAME_REPO}]");

    # try to disconnect
    my $resp  = $conn->disconnect;

    ok(defined($resp), 'disconnect response defined');
    ok( $resp        , "  and success" );

    $resp = $conn->disconnect;
    ok(defined($resp), 'disconnect again');
    ok( $resp        , "  and success" );

}

