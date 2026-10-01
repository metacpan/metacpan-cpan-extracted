use strict;
use warnings;
use Test::More;

use Future;
use URI;
use JSON::MaybeXS;
use HTTP::Response;
use IO::Async::Loop;
use Net::Async::HTTP;
use Net::Async::Kubernetes;

# Regression test for list() dropping labelSelector/fieldSelector (karr k37).
# list() handed both to Kubernetes::REST's build_path, which only builds path
# segments, so list('Pod', labelSelector => 'app=web') sent an unfiltered GET
# and resolved to every Pod -- and ensure_only(), which prunes whatever that
# list returns, would delete everything of the Kind.
#
# No MockTransport here: Net::Async::HTTP::do_request is intercepted instead
# (as in t/22-kubeconfig-inline-tls.t), so the real _do_request runs and the
# assertions see the URI object that goes on the wire. The query is checked by
# decoding it the way the API server does (split on '&', then at the first
# '=', then percent-decode), so the claim is "the server receives exactly the
# selector the caller wrote" -- not one particular escaping of it.

my $loop = IO::Async::Loop->new;
my $JSON = JSON::MaybeXS->new(utf8 => 1);

my $kube = Net::Async::Kubernetes->new(
    server      => { endpoint => 'https://mock.local' },
    credentials => { token => 'mock-token' },
    resource_map_from_cluster => 0,
);
$loop->add($kube);

my $POD_LIST = $JSON->encode({
    kind => 'PodList', apiVersion => 'v1',
    items => [{
        kind => 'Pod', apiVersion => 'v1',
        metadata => { name => 'web-1', namespace => 'default' },
        spec => { containers => [{ name => 'nginx', image => 'nginx' }] },
    }],
});

# Calls list(@args) with the HTTP layer faked; returns the resolved list and
# the URI of every request that was made.
sub list_capturing {
    my (@args) = @_;
    my @uris;
    no warnings 'redefine';
    local *Net::Async::HTTP::do_request = sub {
        my ($http, %req) = @_;
        push @uris, $req{uri};
        return Future->done(HTTP::Response->new(
            200, 'OK', ['Content-Type' => 'application/json'], $POD_LIST));
    };
    my $list = $kube->list(@args)->get;
    return ($list, @uris);
}

sub decoded_query {
    my ($uri) = @_;
    return { URI->new("$uri")->query_form };
}

subtest 'labelSelector reaches the query string (the reported case)' => sub {
    my ($list, @uris) = list_capturing('Pod',
        namespace     => 'default',
        labelSelector => 'app=web',
    );

    is(scalar(@uris), 1, 'exactly one request');
    is($uris[0]->path, '/api/v1/namespaces/default/pods',
        'selector does not leak into the path');
    is_deeply(decoded_query($uris[0]), { labelSelector => 'app=web' },
        'server-side decode yields the labelSelector');

    isa_ok($list, 'IO::K8s::List');
    is(scalar(@{ $list->items }), 1, 'response still inflates');
};

subtest 'fieldSelector reaches the query string' => sub {
    my (undef, @uris) = list_capturing('Pod',
        namespace     => 'default',
        fieldSelector => 'status.phase=Running',
    );

    is($uris[0]->path, '/api/v1/namespaces/default/pods', 'path unchanged');
    is_deeply(decoded_query($uris[0]), { fieldSelector => 'status.phase=Running' },
        'server-side decode yields the fieldSelector');
};

subtest "both selectors, with ',' '=' '!=' '!', arrive unchanged" => sub {
    my $label = 'app=web,tier!=db,!legacy';
    my $field = 'status.phase!=Failed,spec.nodeName=node-1';

    my (undef, @uris) = list_capturing('Pod',
        namespace     => 'default',
        labelSelector => $label,
        fieldSelector => $field,
    );

    is_deeply(decoded_query($uris[0]),
        { labelSelector => $label, fieldSelector => $field },
        'no selector is split at a comma or an inner =, nothing is lost');
};

subtest 'set-based selector with spaces and parentheses arrives unchanged' => sub {
    my $label = 'environment in (production, qa),tier notin (frontend)';

    my (undef, @uris) = list_capturing('Pod',
        namespace     => 'default',
        labelSelector => $label,
    );

    is_deeply(decoded_query($uris[0]), { labelSelector => $label },
        'spaces survive the trip through the URI');
};

subtest 'cluster-wide list (no namespace) keeps the selector' => sub {
    my (undef, @uris) = list_capturing('Pod', labelSelector => 'app=web');

    is($uris[0]->path, '/api/v1/pods', 'cluster-wide path');
    is_deeply(decoded_query($uris[0]), { labelSelector => 'app=web' },
        'selector present on the cluster-wide list');
};

subtest 'without a selector the request carries no query string' => sub {
    my (undef, @uris) = list_capturing('Pod', namespace => 'default');
    is($uris[0]->path_query, '/api/v1/namespaces/default/pods',
        'plain list is unchanged');

    my (undef, @undef_uris) = list_capturing('Pod',
        namespace     => 'default',
        labelSelector => undef,
    );
    is($undef_uris[0]->path_query, '/api/v1/namespaces/default/pods',
        'an undef selector is treated as absent');
};

done_testing;
