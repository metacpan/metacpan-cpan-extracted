use strict;
use warnings;
use Test::More;

use lib 't/lib';

use File::Temp;
use IO::Async::Loop;
use Net::Async::Kubernetes;
use MockTransport;

# karr k62: a context passed without a kubeconfig path is looked up in the
# default kubeconfig. When that fails - the context does not exist, there is
# no kubeconfig at all - the constructor croaks with the reason, as it does
# for an explicit kubeconfig, instead of swallowing it and leaving the first
# request to say "server or kubeconfig required". Without a context, a
# failed auto-detection stays silent as before.
#
# Also on the card: CRD providers through `with`, passed on to
# Kubernetes::REST's constructor, which offers the same option (since 1.108).
#
# Everything runs against kubeconfig fixtures in a throwaway HOME, never the
# config of the machine running the test, and against the mock transport.

my $loop = IO::Async::Loop->new;

# Write $yaml as the kubeconfig of a temporary HOME. Returns the File::Temp
# directory object - which removes the directory once it goes out of scope, so
# the caller has to keep it - and the path of the file inside it.
sub kubeconfig_fixture {
    my ($yaml) = @_;
    my $home = File::Temp->newdir;
    mkdir "$home/.kube" or die "mkdir $home/.kube: $!";
    my $path = "$home/.kube/config";
    open my $fh, '>', $path or die "open $path: $!";
    print $fh $yaml;
    close $fh or die "close $path: $!";
    return ($home, $path);
}

my $KUBECONFIG = <<'YAML';
apiVersion: v1
kind: Config
clusters:
  - name: first-cluster
    cluster:
      server: https://first.fixture.local:6443
      insecure-skip-tls-verify: true
  - name: second-cluster
    cluster:
      server: https://second.fixture.local:6443
      insecure-skip-tls-verify: true
contexts:
  - name: first
    context:
      cluster: first-cluster
      user: fixture-user
  - name: second
    context:
      cluster: second-cluster
      user: fixture-user
current-context: first
users:
  - name: fixture-user
    user:
      token: fixture-token
YAML

subtest 'a context that is not in the default kubeconfig croaks with the reason' => sub {
    my ($home, $path) = kubeconfig_fixture($KUBECONFIG);
    local $ENV{HOME} = "$home";
    local $ENV{KUBECONFIG} = $path;

    my $kube = eval { Net::Async::Kubernetes->new(context => 'absent') };
    like($@, qr/Context not found: absent/, 'the constructor croaks naming the context');
    unlike($@, qr/server or kubeconfig required/, 'not the generic message');
    is($kube, undef, 'no client');
};

subtest 'a context that is in the default kubeconfig is used' => sub {
    my ($home, $path) = kubeconfig_fixture($KUBECONFIG);
    local $ENV{HOME} = "$home";
    local $ENV{KUBECONFIG} = $path;

    my $kube = eval { Net::Async::Kubernetes->new(context => 'second') };
    is($@, '', 'the constructor does not croak');
    is($kube && $kube->server->endpoint, 'https://second.fixture.local:6443',
        'the server comes from that context');
    is($kube && $kube->credentials->token, 'fixture-token', 'and the credentials');
};

subtest 'a context with no kubeconfig anywhere croaks with the reason' => sub {
    plan skip_all => 'running inside a cluster: the service account applies'
        if -e '/var/run/secrets/kubernetes.io/serviceaccount/token';
    my $home = File::Temp->newdir;
    local $ENV{HOME} = "$home";
    local $ENV{KUBECONFIG};
    delete $ENV{KUBECONFIG};

    eval { Net::Async::Kubernetes->new(context => 'absent') };
    like($@, qr/in-cluster/, 'the constructor croaks with why nothing was found');
    unlike($@, qr/server or kubeconfig required/, 'not the generic message');
};

subtest 'without a context a failed auto-detection stays silent' => sub {
    my $home = File::Temp->newdir;
    local $ENV{HOME} = "$home";
    local $ENV{KUBECONFIG};
    delete $ENV{KUBECONFIG};

    my $kube = eval { Net::Async::Kubernetes->new };
    is($@, '', 'the constructor does not croak');
    eval { $kube->server };
    like($@, qr/server or kubeconfig required/, 'the first use says what is missing');
};

subtest 'with: CRD providers reach the resource map' => sub {
    my %connection = (
        server      => { endpoint => 'https://mock.local' },
        credentials => { token => 'mock-token' },
        resource_map_from_cluster => 0,
    );
    my $plain = Net::Async::Kubernetes->new(%connection);
    is_deeply($plain->with, [], 'with defaults to no providers');
    ok(!eval { $plain->expand_class('Gateway'); 1 }, 'premise: without it, Gateway is unknown');

    MockTransport::reset();
    my $kube = Net::Async::Kubernetes->new(%connection, with => ['IO::K8s::GatewayAPI']);
    MockTransport::install($kube);
    $loop->add($kube);
    is_deeply($kube->with, ['IO::K8s::GatewayAPI'], 'with');
    is($kube->expand_class('Gateway'), 'IO::K8s::GatewayAPI::V1::Gateway', 'Gateway resolves through it');

    my $GATEWAYS = '/apis/gateway.networking.k8s.io/v1/namespaces/ns/gateways';
    MockTransport::mock_response('GET', $GATEWAYS, {
        apiVersion => 'gateway.networking.k8s.io/v1', kind => 'GatewayList',
        items      => [ { apiVersion => 'gateway.networking.k8s.io/v1', kind => 'Gateway',
                          metadata => { name => 'gw', namespace => 'ns' } } ],
    });
    my $list = eval { $kube->list('Gateway', namespace => 'ns')->get };
    is($@, '', 'list does not die');
    isa_ok($list && $list->items->[0], 'IO::K8s::GatewayAPI::V1::Gateway', 'a listed Gateway');
    is_deeply([ map { $_->{path} } MockTransport::request_log ], [ $GATEWAYS ], 'at the provider path');

    my $gw = eval { $kube->new_object(Gateway => { metadata => { name => 'gw', namespace => 'ns' } }) };
    isa_ok($gw, 'IO::K8s::GatewayAPI::V1::Gateway', 'new_object');
};

done_testing;
