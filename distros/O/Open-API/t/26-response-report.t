#!perl
use 5.008003;
use strict;
use warnings;
use FindBin ();
use Test::More;
use Open::API;
use Open::API::Plack;
use File::Raw::JSON qw(file_json_decode);

# Report mode: the response is weighed against the schema its status
# declares, and the finding goes to a callback - the triplet the client
# receives is the one the handler built, byte for byte. Plus the sampling
# gate and the skip rules, each of which has to move its own counter,
# because coverage is a reported number rather than a silent gap.

my $spec = "$FindBin::Bin/spec/petstore.json";

sub get_pet {
    my ($app, %o) = @_;
    open my $in, '<', \(my $b = '') or die;
    return $app->({
        REQUEST_METHOD => 'GET',
        PATH_INFO      => $o{path} || '/pets/1',
        QUERY_STRING   => '',
        'psgi.input'   => $in,
    });
}

# ---- report mode never touches the response ---------------------------------
{
    my $api = Open::API->new(spec => $spec);
    my @seen;
    my $body = File::Raw::JSON::file_json_encode({ wrong => 'shape' });
    my $trip = [ 200,
                 [ 'Content-Type'   => 'application/json',
                   'Content-Length' => length $body,
                   'X-Upstream'     => 'yes' ],
                 [ $body ] ];

    my $app = Open::API::Plack->new(
        api                => $api,
        validate_responses => {
            mode   => 'report',
            report => sub { push @seen, [ @_ ] },
        },
        handlers => { getPet => sub { $trip } },
    )->to_app;

    my $r = get_pet($app);

    is($r->[0], 200, 'report mode leaves the status alone');
    is_deeply($r->[1], $trip->[1], '...and every header, in order');
    is($r->[2][0], $body, '...and the body byte for byte');

    is(scalar @seen, 1, 'the callback saw the violation');
    is($seen[0][0], 'getPet', 'op_id');
    is($seen[0][1], 200, 'status');
    isa_ok($seen[0][2], 'ARRAY', 'errors');
    is($seen[0][2][0]{in}, 'response', 'errors are marked in=response');
    isa_ok($seen[0][3], 'HASH', 'the env');
    is($seen[0][3]{PATH_INFO}, '/pets/1', '...the request that produced it');

    my $cov = $api->response_coverage('getPet');
    is($cov->{total}, 1, 'coverage: one response seen');
    is($cov->{checked}, 1, '...one checked');
    is($cov->{violations}, 1, '...one violation');
}

# ---- a conforming response reports nothing ----------------------------------
{
    my $api = Open::API->new(spec => $spec);
    my @seen;
    my $body = File::Raw::JSON::file_json_encode({ id => 1, name => 'rex' });
    my $app = Open::API::Plack->new(
        api                => $api,
        validate_responses => { mode => 'report',
                                report => sub { push @seen, [ @_ ] } },
        handlers => { getPet => sub {
            [ 200, [ 'Content-Type' => 'application/json',
                     'Content-Length' => length $body ], [ $body ] ] } },
    )->to_app;

    my $r = get_pet($app);
    is($r->[0], 200, 'conforming response passes through');
    is(scalar @seen, 0, 'and reports nothing');
    my $cov = $api->response_coverage('getPet');
    is($cov->{checked}, 1, 'it was checked');
    is($cov->{violations}, 0, 'and conformed');
}

# ---- replace mode is exactly what it was ------------------------------------
{
    my $api = Open::API->new(spec => $spec);
    my $app = Open::API::Plack->new(
        api => $api, validate_responses => 1,
        handlers => { getPet => sub { { wrong => 'shape' } } },
    )->to_app;
    my $r = get_pet($app);
    is($r->[0], 500, 'replace mode still replaces the response');
    is(file_json_decode($r->[2][0])->{errors}[0]{in}, 'response',
        '...with the pointer list');
}

# ---- the sampling gate ------------------------------------------------------
{
    my $api = Open::API->new(spec => $spec);
    my @seen;
    my $body = File::Raw::JSON::file_json_encode({ wrong => 'shape' });
    my $app = Open::API::Plack->new(
        api                => $api,
        validate_responses => { mode => 'report', sample => 4,
                                report => sub { push @seen, [ @_ ] } },
        handlers => { getPet => sub {
            [ 200, [ 'Content-Type' => 'application/json',
                     'Content-Length' => length $body ], [ $body ] ] } },
    )->to_app;

    get_pet($app) for 1 .. 12;

    my $cov = $api->response_coverage('getPet');
    is($cov->{total}, 12, 'every response is counted');
    is($cov->{sampled}, 3, '1-in-4 is sampled - deterministic, not a draw');
    is($cov->{unsampled}, 9, 'the rest are counted as unsampled');
    is(scalar @seen, 3, 'and only the sampled ones are reported');
}

# ---- skip: not a JSON content type ------------------------------------------
{
    my $api = Open::API->new(spec => $spec);
    my @seen;
    my $app = Open::API::Plack->new(
        api                => $api,
        validate_responses => { mode => 'report',
                                report => sub { push @seen, [ @_ ] } },
        handlers => { getPet => sub {
            [ 200, [ 'Content-Type' => 'text/html' ], [ '<p>not json</p>' ] ] } },
    )->to_app;

    my $r = get_pet($app);
    is($r->[2][0], '<p>not json</p>', 'the body is forwarded untouched');
    my $cov = $api->response_coverage('getPet');
    is($cov->{skip_ctype}, 1, 'skip_ctype moved');
    is($cov->{checked}, 0, 'nothing was decoded');
    is(scalar @seen, 0, 'nothing reported');
}

# ---- skip: no Content-Length, or over the cap -------------------------------
{
    my $api = Open::API->new(spec => $spec);
    my $big = File::Raw::JSON::file_json_encode({ id => 1, name => 'x' x 500 });
    my $app = Open::API::Plack->new(
        api                => $api,
        validate_responses => { mode => 'report', max_body => 100,
                                report => sub { } },
        handlers => { getPet => sub {
            [ 200, [ 'Content-Type' => 'application/json',
                     'Content-Length' => length $big ], [ $big ] ] } },
    )->to_app;

    get_pet($app);
    my $cov = $api->response_coverage('getPet');
    is($cov->{skip_size}, 1, 'a body over max_body is skipped by size');
    is($cov->{checked}, 0, 'and never decoded');
}
{
    my $api = Open::API->new(spec => $spec);
    my $body = File::Raw::JSON::file_json_encode({ id => 1, name => 'rex' });
    my $app = Open::API::Plack->new(
        api                => $api,
        validate_responses => { mode => 'report', max_body => 1000,
                                report => sub { } },
        handlers => { getPet => sub {
            [ 200, [ 'Content-Type' => 'application/json' ], [ $body ] ] } },
    )->to_app;

    get_pet($app);
    is($api->response_coverage('getPet')->{skip_size}, 1,
        'an absent Content-Length under a cap is a size skip: '
      . 'an unmeasured body is not buffered to find out');
}

# ---- skip: the body is not a plain scalar -----------------------------------
{
    my $api = Open::API->new(spec => $spec);
    open my $fh, '<', \(my $bytes = '{"id":1}') or die;
    my $app = Open::API::Plack->new(
        api                => $api,
        validate_responses => { mode => 'report', report => sub { } },
        handlers => { getPet => sub {
            [ 200, [ 'Content-Type' => 'application/json',
                     'Content-Length' => 8 ], $fh ] } },
    )->to_app;

    my $r = get_pet($app);
    is(ref $r->[2], 'GLOB', 'a filehandle body is handed back as it is');
    my $cov = $api->response_coverage('getPet');
    is($cov->{skip_body}, 1, 'skip_body moved');
    is($cov->{checked}, 0, 'and it was never read');
}

# ---- skip: the status declares no schema ------------------------------------
{
    my $api = Open::API->new(spec => $spec);
    my $body = File::Raw::JSON::file_json_encode({ anything => 1 });
    my $app = Open::API::Plack->new(
        api                => $api,
        validate_responses => { mode => 'report', report => sub { } },
        handlers => { deletePet => sub {
            [ 204, [ 'Content-Type' => 'application/json',
                     'Content-Length' => length $body ], [ $body ] ] } },
    )->to_app;

    open my $in, '<', \(my $b = '') or die;
    my $r = $app->({ REQUEST_METHOD => 'DELETE', PATH_INFO => '/pets/1',
                     QUERY_STRING => '', 'psgi.input' => $in,
                     HTTP_COOKIE => 'session=abc' });   # the op requires it
    is($r->[0], 204, 'the handler answered');

    my $cov = $api->response_coverage('deletePet');
    is($cov->{total}, 1, 'the response was seen');
    is($cov->{skip_schema}, 1, 'and skipped: 204 declares no schema');
}

# ---- coverage for every operation at once -----------------------------------
{
    my $api = Open::API->new(spec => $spec);
    my $body = File::Raw::JSON::file_json_encode({ id => 1, name => 'rex' });
    my $app = Open::API::Plack->new(
        api                => $api,
        validate_responses => { mode => 'report', report => sub { } },
        handlers => { getPet => sub {
            [ 200, [ 'Content-Type' => 'application/json',
                     'Content-Length' => length $body ], [ $body ] ] } },
    )->to_app;

    get_pet($app) for 1 .. 2;
    my $all = $api->response_coverage;
    is_deeply([ sort keys %$all ], [ 'getPet' ],
        'only operations that have seen a response appear');
    is($all->{getPet}{total}, 2, 'with their counters');
}

# ---- the direct entry point, which is what a proxy uses ---------------------
{
    my $api = Open::API->new(spec => $spec);
    my $bad = File::Raw::JSON::file_json_encode({ wrong => 'shape' });
    my $trip = [ 200, [ 'Content-Type' => 'application/json',
                        'Content-Length' => length $bad ], [ $bad ] ];

    my $errs = $api->check_response('getPet', $trip);
    isa_ok($errs, 'ARRAY', 'check_response returns the errors');
    is($errs->[0]{in}, 'response', 'marked in=response');
    is($trip->[0], 200, 'and the triplet is untouched');
    is($trip->[2][0], $bad, '...body included');

    my $good = File::Raw::JSON::file_json_encode({ id => 1, name => 'rex' });
    is($api->check_response('getPet',
        [ 200, [ 'Content-Type' => 'application/json',
                 'Content-Length' => length $good ], [ $good ] ]),
       undef, 'undef when the response conforms');

    my $cov = $api->response_coverage('getPet');
    is($cov->{total}, 2, 'the direct path counts too');
    is($cov->{violations}, 1, 'one of them a violation');
}

# ---- a report callback that dies loses the sample, not the response ---------
{
    my $api = Open::API->new(spec => $spec);
    my $bad = File::Raw::JSON::file_json_encode({ wrong => 'shape' });
    my $app = Open::API::Plack->new(
        api                => $api,
        validate_responses => { mode => 'report',
                                report => sub { die "reporter is down\n" } },
        handlers => { getPet => sub {
            [ 200, [ 'Content-Type' => 'application/json',
                     'Content-Length' => length $bad ], [ $bad ] ] } },
    )->to_app;

    my $r;
    my @warnings;
    {
        local $SIG{__WARN__} = sub { push @warnings, $_[0] };
        $r = get_pet($app);
    }
    is($r->[0], 200, 'the response is delivered anyway');
    is($r->[2][0], $bad, '...unchanged');
    like($warnings[0] || '', qr/reporter is down/, 'the failure is warned');
}

# ---- configuration errors are boot errors -----------------------------------
{
    my $api = Open::API->new(spec => $spec);
    eval {
        Open::API::Plack->new(api => $api, validate_responses => 'report',
                              handlers => {})->to_app;
    };
    like($@, qr/needs somewhere to report to/,
        "report mode without a callback croaks at to_app, not per request");

    eval {
        Open::API::Plack->new(api => $api, validate_responses => 'sometimes',
                              handlers => {})->to_app;
    };
    like($@, qr/must be 0, 1, 'replace', 'report'/,
        'an unknown mode names the ones there are');
}

# ---- operation_info: the resolved contract ----------------------------------
{
    my $api  = Open::API->new(spec => $spec);
    my $info = $api->operation_info('getPet');
    is($info->{operationId}, 'getPet', 'operationId');
    is($info->{method}, 'get', 'method');
    is($info->{path}, '/pets/{petId}', 'path');
    my ($petid) = grep { $_->{name} eq 'petId' } @{ $info->{parameters} };
    ok($petid, 'the path parameter is listed');
    is($petid->{in}, 'path', '...with where it comes from');
    ok($petid->{required}, '...and whether it must be there');
    # the compiled contract, not the document: petstore's 404 declares no
    # content, so nothing was compiled for it and nothing will be checked
    is_deeply([ sort map { $_->{status} } @{ $info->{responses} } ],
              [ '200' ], 'the statuses that carry a schema');
    ok($info->{responses}[0]{validated},
        'and whether a schema will actually be checked');
    is($info->{responses}[0]{content_type}, 'application/json',
        'with the content type it is declared under');
}

done_testing();
