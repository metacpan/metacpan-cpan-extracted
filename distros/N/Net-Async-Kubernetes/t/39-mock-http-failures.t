use strict;
use warnings;
use Test::More;

use lib 't/lib';

use IO::Async::Loop;
use Kubernetes::REST::HTTPResponse;
use Net::Async::Kubernetes;
use MockTransport;

# karr k61: an API server's refusal (status >= 400) fails the Future the way
# Future's convention has it - ->fail($error, 'http', $response). $error is
# exactly what Kubernetes::REST's check_response throws, the
# Kubernetes::REST::APIError object, handed on as it is, so its text does not
# change; $response is the Kubernetes::REST::HTTPResponse, so a caller
# tells a 404 or 409 from anything else by ->status instead of parsing text:
#
#   $kube->delete(...)->catch(http => sub {
#       my ($error, undef, $response) = @_;
#       return Future->done if $response->status == 404;
#       return Future->fail(@_);
#   });
#
# Mock-only: the mock transport answers with the status under test.

my $loop = IO::Async::Loop->new;

sub make_kube {
    MockTransport::reset();
    my $kube = Net::Async::Kubernetes->new(
        server      => { endpoint => 'https://mock.local' },
        credentials => { token => 'mock-token' },
        resource_map_from_cluster => 0,
    );
    MockTransport::install($kube);
    $loop->add($kube);
    return $kube;
}

my $CMS  = '/api/v1/namespaces/default/configmaps';
my $JOBS = '/apis/batch/v1/namespaces/default/jobs';

sub status_body {
    my ($code) = @_;
    return { kind => 'Status', apiVersion => 'v1', status => 'Failure',
        code => $code, message => "mock answers $code" };
}

sub cm {
    my ($kube, %extra) = @_;
    return $kube->new_object(ConfigMap => {
        metadata => { name => 'cm1', namespace => 'default', resourceVersion => '1' },
        %extra,
    });
}

# What check_response throws for $response in $context, without the location
# a croak ends in (it differs by where the croak is caught).
sub thrown_by_check_response {
    my ($kube, $response, $context) = @_;
    my $thrown = eval { $kube->rest->check_response($response, $context); 1 } ? undef : $@;
    return $thrown;
}

sub without_location {
    my ($error) = @_;
    (my $text = "$error") =~ s/ at \S+ line \d+\.\n?\z//;
    return $text;
}

# $f failed as an HTTP refusal with $code; $context is what the message names.
sub check_http_failure {
    my ($kube, $label, $f, $code, $context) = @_;
    ok($f && $f->is_failed, "$label: the Future failed") or return;
    my ($error, $category, $response, @rest) = $f->failure;
    is($category, 'http', "$label: category http");
    isa_ok($response, 'Kubernetes::REST::HTTPResponse', "$label: the response");
    is($response && $response->status, $code, "$label: the response carries status $code");
    is(scalar @rest, 0, "$label: nothing after the response");
    my $expected = thrown_by_check_response($kube, $response, $context);
    is(without_location($error), without_location($expected),
        "$label: the message is what check_response throws");
    like("$error", qr/\AKubernetes API error \(\Q$context\E\): $code /, "$label: the message text");
}

subtest 'every request method fails with category http and the response' => sub {
    for my $code (404, 409, 500) {
        my $kube = make_kube();
        MockTransport::mock_response($_, $CMS, status_body($code), $code) for qw(GET POST);
        MockTransport::mock_response($_, "$CMS/cm1", status_body($code), $code) for qw(GET PUT PATCH DELETE);
        MockTransport::mock_response($_, "$CMS/cm1/status", status_body($code), $code) for qw(PUT PATCH);
        MockTransport::mock_response('GET', '/api/v1/namespaces/default/pods/p1/log', status_body($code), $code);

        my $object = cm($kube);
        for my $call (
            [ list          => sub { $kube->list('ConfigMap', namespace => 'default') }, 'list ConfigMap' ],
            [ get           => sub { $kube->get('ConfigMap', 'cm1', namespace => 'default') }, 'get ConfigMap' ],
            [ create        => sub { $kube->create($object) }, 'create ' . ref($object) ],
            [ update        => sub { $kube->update($object) }, 'update ' . ref($object) ],
            [ update_status => sub { $kube->update_status($object) }, 'update_status ' . ref($object) ],
            [ patch         => sub { $kube->patch('ConfigMap', 'cm1', namespace => 'default', patch => {}) },
              'patch ' . ref($object) ],
            [ patch_status  => sub { $kube->patch_status($object, patch => { status => {} }) },
              'patch_status ' . ref($object) ],
            [ delete        => sub { $kube->delete('ConfigMap', 'cm1', namespace => 'default') },
              'delete ' . ref($object) ],
            [ log           => sub { $kube->log('Pod', 'p1', namespace => 'default') }, 'log Pod' ],
        ) {
            my ($method, $code_ref, $context) = @$call;
            my $f = eval { $code_ref->() };
            is($@, '', "$method ($code): does not croak");
            $f->await if $f;
            check_http_failure($kube, "$method ($code)", $f, $code, $context);
        }
    }
};

subtest 'a streamed log refused by the API server fails the same way' => sub {
    my $kube = make_kube();
    # The chunks are not streamed at an error status (karr k53), as the real
    # transport keeps an error body for check_response.
    MockTransport::mock_stream_chunks('/api/v1/namespaces/default/pods/p1/log',
        [ "not a log line\n" ], { status => 403 });
    my @lines;
    my $f = $kube->log('Pod', 'p1', namespace => 'default', follow => 1,
        on_line => sub { push @lines, $_[0] });
    my $timer = $loop->watch_time(after => 2, code => sub { $f->fail('timeout') unless $f->is_ready });
    $loop->await($f);
    $loop->unwatch_time($timer);
    ok($f->is_failed, 'the Future failed');
    my (undef, $category, $response) = $f->failure;
    is($category, 'http', 'category http');
    is($response && $response->status, 403, 'the response carries status 403');
    is_deeply(\@lines, [], 'no line was delivered');
};

subtest 'ensure and ensure_all fail with category http and the response' => sub {
    for my $case (
        # [ label, mocks, status, context ]
        [ 'GET refused', sub {
              MockTransport::mock_response('GET', "$CMS/cm1", status_body(403), 403);
          }, 403, 'ensure get ConfigMap/cm1' ],
        [ 'POST refused', sub {
              MockTransport::mock_response('GET', "$CMS/cm1", status_body(404), 404);
              MockTransport::mock_response('POST', $CMS, status_body(422), 422);
          }, 422, 'create IO::K8s::Api::Core::V1::ConfigMap' ],
        [ 'PUT refused', sub {
              MockTransport::mock_response('GET', "$CMS/cm1",
                  { kind => 'ConfigMap', apiVersion => 'v1',
                    metadata => { name => 'cm1', namespace => 'default', resourceVersion => '5' } });
              MockTransport::mock_response('PUT', "$CMS/cm1", status_body(500), 500);
          }, 500, 'update IO::K8s::Api::Core::V1::ConfigMap' ],
        [ 'refetch after a 409 refused', sub {
              MockTransport::mock_response_queue('GET', "$CMS/cm1",
                  [ { kind => 'ConfigMap', apiVersion => 'v1',
                      metadata => { name => 'cm1', namespace => 'default', resourceVersion => '5' } }, 200 ],
                  [ status_body(404), 404 ]);
              MockTransport::mock_response('PUT', "$CMS/cm1", status_body(409), 409);
          }, 404, 'ensure refetch ConfigMap/cm1' ],
        [ 'retried update after a 409 refused', sub {
              MockTransport::mock_response('GET', "$CMS/cm1",
                  { kind => 'ConfigMap', apiVersion => 'v1',
                    metadata => { name => 'cm1', namespace => 'default', resourceVersion => '5' } });
              MockTransport::mock_response('PUT', "$CMS/cm1", status_body(409), 409);
          }, 409, 'update IO::K8s::Api::Core::V1::ConfigMap' ],
    ) {
        my ($label, $mocks, $code, $context) = @$case;
        for my $method (qw( ensure ensure_all )) {
            my $kube = make_kube();
            $mocks->();
            my $f = eval { $kube->$method(cm($kube)) };
            is($@, '', "$method, $label: does not croak");
            $f->await if $f;
            check_http_failure($kube, "$method, $label", $f, $code, $context);
        }
    }
};

subtest 'a caller can catch the http category and branch on the status' => sub {
    my $kube = make_kube();
    MockTransport::mock_response('DELETE', "$CMS/gone", status_body(404), 404);
    MockTransport::mock_response('DELETE', "$CMS/locked", status_body(403), 403);

    my $already_gone = sub {
        my ($f) = @_;
        return $f->catch(http => sub {
            my ($error, $category, $response) = @_;
            return Future->done('gone') if $response->status == 404;
            return Future->fail(@_);
        });
    };
    is(eval { $already_gone->($kube->delete('ConfigMap', 'gone', namespace => 'default'))->get },
        'gone', 'a 404 is caught as already gone');
    my $f = $already_gone->($kube->delete('ConfigMap', 'locked', namespace => 'default'));
    $f->await;
    ok($f->is_failed, 'a 403 still fails');
    is(($f->failure)[2]->status, 403, 'with its own response');

    # An argument error is no HTTP failure: no category, no response.
    my $bad = $kube->delete('ConfigMap');
    ok($bad->is_failed, 'an argument error fails the Future');
    is_deeply([ ($bad->failure)[1 .. 2] ], [ undef, undef ], 'without category or response');
};

subtest 'a Kubernetes::REST::APIError from check_response is handed on as it is' => sub {
    my $kube = make_kube();
    MockTransport::mock_response('GET', "$CMS/cm1", status_body(404), 404);
    my $f = $kube->get('ConfigMap', 'cm1', namespace => 'default');
    $f->await;
    my ($error, $category, $response) = $f->failure;
    isa_ok($error, 'Kubernetes::REST::APIError', 'the failure message');
    is($category, 'http', 'category http');
    is($response && $response->status, 404, 'the response');
    like("$error", qr/\AKubernetes API error \(get ConfigMap\): 404 /, 'it stringifies to the message');
};

done_testing;
