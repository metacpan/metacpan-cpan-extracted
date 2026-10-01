use strict;
use warnings;
use Test::More;

use lib 't/lib';

use IO::Async::Loop;
use Net::Async::Kubernetes;
use MockTransport;

# karr k60 (as Kubernetes::REST k49): delete() sends DeleteOptions'
# propagationPolicy as a query parameter, in every call form. Without it the
# API server applies the resource's default, which for a Job is to orphan
# its Pods. A value the API server does not know, and any option delete()
# does not know - a typo would silently drop the policy - fail the Future
# before a request is sent - worded as Kubernetes::REST words them (karr
# k64), naming only the first unknown option. ensure_only() prunes with
# propagationPolicy Background unless told otherwise, and ensure() deletes a
# failed Job with Background before recreating it.
#
# Mock-only: the policy is checked in the query string of the request.

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

sub requests {
    my ($method) = @_;
    return [ map { $_->{path} } grep { $_->{method} eq $method } MockTransport::request_log ];
}

sub failure_of {
    my ($f) = @_;
    return $f && $f->is_failed ? ($f->failure)[0] : undef;
}

my $JOBS      = '/apis/batch/v1/namespaces/default/jobs';
my $CMS       = '/api/v1/namespaces/default/configmaps';
my $SUCCESS   = { kind => 'Status', apiVersion => 'v1', status => 'Success' };
my $NOT_FOUND = { kind => 'Status', status => 'Failure', message => 'not found', code => 404 };
my $USE       = qr/\(use: Background, Foreground, Orphan\)/;

sub job {
    my ($kube, %status) = @_;
    return $kube->new_object(Job => {
        metadata => { name => 'job1', namespace => 'default' },
        spec     => { template => { spec => { restartPolicy => 'Never',
            containers => [ { name => 'c', image => 'busybox' } ] } } },
        (%status ? (status => \%status) : ()),
    });
}

subtest 'delete sends propagationPolicy in every call form' => sub {
    for my $policy (qw( Background Foreground Orphan )) {
        my $kube = make_kube();
        MockTransport::mock_response('DELETE', "$JOBS/job1?propagationPolicy=$policy", $SUCCESS);

        for my $call (
            [ object    => sub { $kube->delete(job($kube), propagationPolicy => $policy) } ],
            [ shorthand => sub { $kube->delete('Job', 'job1', namespace => 'default', propagationPolicy => $policy) } ],
            [ keyed     => sub { $kube->delete('Job', name => 'job1', namespace => 'default', propagationPolicy => $policy) } ],
            [ 'keyed, policy first' => sub { $kube->delete('Job', propagationPolicy => $policy, name => 'job1', namespace => 'default') } ],
        ) {
            my ($form, $code) = @$call;
            my $result = eval { $code->()->get };
            is($@, '', "$policy, $form form: delete does not die");
            is($result, 1, "$policy, $form form: resolves to 1");
        }
        is_deeply(requests('DELETE'), [ ("$JOBS/job1?propagationPolicy=$policy") x 4 ],
            "$policy: every form sends it as a query parameter");
    }
};

subtest 'delete without propagationPolicy leaves the default to the server' => sub {
    my $kube = make_kube();
    MockTransport::mock_response('DELETE', "$JOBS/job1", $SUCCESS);
    eval { $kube->delete('Job', 'job1', namespace => 'default')->get };
    is($@, '', 'delete does not die');
    eval { $kube->delete(job($kube))->get };
    is($@, '', 'delete (object) does not die');
    eval { $kube->delete('Job', 'job1', namespace => 'default', propagationPolicy => undef)->get };
    is($@, '', 'delete with an undef propagationPolicy does not die');
    is_deeply(requests('DELETE'), [ ("$JOBS/job1") x 3 ], 'no query string');
};

subtest 'an unknown propagationPolicy fails the Future before a request' => sub {
    my $kube = make_kube();
    for my $call (
        [ object    => sub { $kube->delete(job($kube), propagationPolicy => 'background') } ],
        [ shorthand => sub { $kube->delete('Job', 'job1', namespace => 'default', propagationPolicy => 'Cascade') } ],
        [ keyed     => sub { $kube->delete('Job', name => 'job1', propagationPolicy => '') } ],
    ) {
        my ($form, $code) = @$call;
        my $f = eval { $code->() };
        is($@, '', "$form form: delete does not croak");
        like(failure_of($f) // '', qr/\AUnknown propagationPolicy '[^']*' for delete\(\) $USE\z/,
            "$form form: the failure names the allowed values");
    }
    is_deeply([ MockTransport::request_log ], [], 'no request was sent');
};

subtest 'an unknown option fails the Future before a request' => sub {
    my $kube = make_kube();
    for my $call (
        [ 'object, typo'      => sub { $kube->delete(job($kube), propagation_policy => 'Background') },
          qr/\AUnknown argument 'propagation_policy' to delete\(\) \(allowed: propagationPolicy\)\z/ ],
        [ 'object, namespace' => sub { $kube->delete(job($kube), namespace => 'other') },
          qr/\AUnknown argument 'namespace' to delete\(\) \(allowed: propagationPolicy\)\z/ ],
        [ 'shorthand, typo'   => sub { $kube->delete('Job', 'job1', namespace => 'default', propagationpolicy => 'Background') },
          qr/\AUnknown argument 'propagationpolicy' to delete\(\) \(allowed: name, namespace, propagationPolicy\)\z/ ],
        [ 'keyed, two typos'  => sub { $kube->delete('Job', name => 'job1', gracePeriod => 0, force => 1) },
          qr/\AUnknown argument 'force' to delete\(\) \(allowed: name, namespace, propagationPolicy\)\z/ ],
        [ 'object, odd list'  => sub { $kube->delete(job($kube), 'propagationPolicy') },
          qr/\AInvalid arguments to delete\(\)\z/ ],
    ) {
        my ($form, $code, $want) = @$call;
        my $f = eval { $code->() };
        is($@, '', "$form: delete does not croak");
        like(failure_of($f) // '', $want, "$form: the Future fails with the option error");
    }
    is_deeply([ MockTransport::request_log ], [], 'no request was sent');
};

subtest 'ensure_only prunes with propagationPolicy Background by default' => sub {
    my $kube = make_kube();
    my $item = sub {
        my ($name) = @_;
        return { kind => 'ConfigMap', apiVersion => 'v1',
            metadata => { name => $name, namespace => 'default', labels => { app => 'demo' } } };
    };
    my $setup = sub {
        MockTransport::reset();
        MockTransport::mock_response('GET', "$CMS/keep", $NOT_FOUND, 404);
        MockTransport::mock_response('POST', $CMS, $item->('keep'));
        MockTransport::mock_response('GET', "$CMS?labelSelector=app=demo",
            { kind => 'ConfigMapList', apiVersion => 'v1', items => [ $item->('keep'), $item->('stale') ] });
        MockTransport::mock_response('DELETE', "$CMS/stale?propagationPolicy=$_", $SUCCESS)
            for qw( Background Foreground );
    };
    my @args = (
        label      => 'app=demo',
        objects    => [ $item->('keep') ],
        kinds      => ['ConfigMap'],
        namespaces => ['default'],
    );

    $setup->();
    my @warnings;
    eval {
        local $SIG{__WARN__} = sub { push @warnings, $_[0] };
        $kube->ensure_only(@args)->get;
    };
    is($@, '', 'ensure_only does not die');
    is_deeply(\@warnings, [], 'no warnings');
    is_deeply(requests('DELETE'), [ "$CMS/stale?propagationPolicy=Background" ],
        'the stale object is deleted with Background');

    $setup->();
    eval { $kube->ensure_only(@args, propagationPolicy => 'Foreground')->get };
    is($@, '', 'ensure_only (Foreground) does not die');
    is_deeply(requests('DELETE'), [ "$CMS/stale?propagationPolicy=Foreground" ],
        'an explicit propagationPolicy is used instead');

    $setup->();
    my $croak = eval { $kube->ensure_only(@args, propagationPolicy => 'orphan'); 1 } ? '' : $@;
    like($croak, qr/\AUnknown propagationPolicy 'orphan' for ensure_only\(\) $USE at /,
        'an unknown propagationPolicy croaks');
    is_deeply([ MockTransport::request_log ], [], 'before any request');
};

subtest 'ensure deletes a failed Job with propagationPolicy Background' => sub {
    my $kube = make_kube();
    MockTransport::mock_response('GET', "$JOBS/job1", {
        apiVersion => 'batch/v1', kind => 'Job',
        metadata   => { name => 'job1', namespace => 'default', resourceVersion => '3' },
        status     => { failed => 1 },
    });
    MockTransport::mock_response('DELETE', "$JOBS/job1?propagationPolicy=Background", $SUCCESS);
    MockTransport::mock_response('POST', $JOBS, {
        apiVersion => 'batch/v1', kind => 'Job',
        metadata   => { name => 'job1', namespace => 'default', resourceVersion => '4' },
    });

    my $result = eval { $kube->ensure(job($kube))->get };
    is($@, '', 'ensure does not die');
    is($result && $result->metadata->resourceVersion, '4', 'the recreated Job');
    is_deeply([ map { "$_->{method} $_->{path}" } MockTransport::request_log ],
        [ "GET $JOBS/job1", "DELETE $JOBS/job1?propagationPolicy=Background", "POST $JOBS" ],
        'GET, DELETE with Background, POST');
};

done_testing;
