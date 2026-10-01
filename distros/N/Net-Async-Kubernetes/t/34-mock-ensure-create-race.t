use strict;
use warnings;
use Test::More;

use lib 't/lib';

use IO::Async::Loop;
use JSON::MaybeXS;
use Net::Async::Kubernetes;
use MockTransport;

# karr k49 (Kubernetes::REST k41): the object appears between ensure's GET
# and its POST, and the POST answers 409 AlreadyExists. From there on it is an
# existing object like any other: a batch/v1 Job gets the Job special case -
# kept while active or succeeded, deleted and recreated otherwise, never a
# PUT onto its immutable Pod template - a PersistentVolumeClaim is returned
# unchanged, and anything else is updated at the server's resourceVersion
# with the same one conflict retry as on the main path.
#
# t/21-mock-ensure.t covers the create race for a Pod and a PVC.
#
# Mock-only: everything here is request routing, nothing needs a cluster.

my $loop = IO::Async::Loop->new;
my $JSON = JSON::MaybeXS->new(utf8 => 1);

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

sub calls {
    return [ map { "$_->{method} $_->{path}" } MockTransport::request_log ];
}

my $JOBS = '/apis/batch/v1/namespaces/default/jobs';
my $BG   = '?propagationPolicy=Background';
my $CMS  = '/api/v1/namespaces/default/configmaps';

sub failure {
    my ($code, $reason) = @_;
    return [ { kind => 'Status', apiVersion => 'v1', status => 'Failure',
               code => $code, reason => $reason, message => $reason }, $code ];
}

sub job {
    my ($name, %extra) = @_;
    return {
        apiVersion => 'batch/v1', kind => 'Job',
        metadata   => { name => $name, namespace => 'default' },
        spec       => { template => { spec => {
            containers    => [ { name => 'c', image => 'busybox' } ],
            restartPolicy => 'Never',
        } } },
        %extra,
    };
}

sub served {
    my ($manifest, $rv) = @_;
    return [ { %$manifest, metadata => { %{ $manifest->{metadata} }, resourceVersion => $rv } }, 200 ];
}

subtest 'an active Job that appeared is returned as it is, no PUT' => sub {
    my $kube = make_kube();
    MockTransport::mock_response_queue('GET', "$JOBS/late",
        failure(404, 'NotFound'), served(job('late', status => { active => 1 }), '11'));
    MockTransport::mock_response_queue('POST', $JOBS, failure(409, 'AlreadyExists'));

    my $result = eval { $kube->ensure(job('late'))->get };
    is($@, '', 'ensure resolves');
    is_deeply(calls(), [ "GET $JOBS/late", "POST $JOBS", "GET $JOBS/late" ],
        'returned unchanged - no PUT onto the Pod template');
    is($result && $result->metadata->resourceVersion, '11', 'the existing Job is returned');
};

subtest 'a failed Job that appeared is deleted and recreated, as on the main path' => sub {
    my $kube = make_kube();
    MockTransport::mock_response_queue('GET', "$JOBS/late",
        failure(404, 'NotFound'), served(job('late', status => { failed => 1 }), '11'));
    MockTransport::mock_response_queue('POST', $JOBS,
        failure(409, 'AlreadyExists'), served(job('late'), '12'));
    MockTransport::mock_response('DELETE', "$JOBS/late$BG",
        { kind => 'Status', apiVersion => 'v1', status => 'Success' });

    my $result = eval { $kube->ensure(job('late'))->get };
    is($@, '', 'ensure resolves');
    is_deeply(calls(),
        [ "GET $JOBS/late", "POST $JOBS", "GET $JOBS/late", "DELETE $JOBS/late$BG", "POST $JOBS" ],
        'deleted and recreated, no PUT');
    is($result && $result->metadata->resourceVersion, '12', 'the recreated Job is returned');
};

subtest 'any other object that appeared is updated, and a conflict there is retried once' => sub {
    my $cm = {
        apiVersion => 'v1', kind => 'ConfigMap',
        metadata   => { name => 'late', namespace => 'default' },
        data       => { key => 'value' },
    };

    my $kube = make_kube();
    MockTransport::mock_response_queue('GET', "$CMS/late",
        failure(404, 'NotFound'), served($cm, '7'), served($cm, '9'));
    MockTransport::mock_response_queue('POST', $CMS, failure(409, 'AlreadyExists'));
    MockTransport::mock_response_queue('PUT', "$CMS/late", failure(409, 'Conflict'), served($cm, '10'));

    my $object = $kube->new_object(ConfigMap => $cm);
    my $result = eval { $kube->ensure($object)->get };
    is($@, '', 'ensure resolves');
    is_deeply(calls(),
        [ "GET $CMS/late", "POST $CMS", "GET $CMS/late", "PUT $CMS/late", "GET $CMS/late", "PUT $CMS/late" ],
        'updated; the conflicting update is refetched and retried once');
    my @puts = grep { $_->{method} eq 'PUT' } MockTransport::request_log;
    is_deeply([ map { $JSON->decode($_->{content})->{metadata}{resourceVersion} } @puts ], [ '7', '9' ],
        'each PUT carries the resourceVersion of the GET before it');
    is($result && $result->metadata->resourceVersion, '10', 'the updated object is returned');
};

done_testing;
