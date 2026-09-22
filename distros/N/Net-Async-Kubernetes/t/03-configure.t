use strict;
use warnings;
use Test::More;
use Test::Exception;
use File::Temp ();

use IO::Async::Loop;
use Net::Async::Kubernetes;
use Kubernetes::REST::Server;
use Kubernetes::REST::AuthToken;

my $loop = IO::Async::Loop->new;

# ============================================================================
# Constructor with server + credentials (hashref coercion)
# ============================================================================

subtest 'new with server/credentials hashrefs' => sub {
    my $kube = Net::Async::Kubernetes->new(
        server      => { endpoint => 'https://k8s.local:6443' },
        credentials => { token => 'my-token' },
    );
    isa_ok($kube, 'Net::Async::Kubernetes');
    isa_ok($kube, 'IO::Async::Notifier');
    isa_ok($kube->server, 'Kubernetes::REST::Server');
    is($kube->server->endpoint, 'https://k8s.local:6443', 'server endpoint');
    is($kube->credentials->token, 'my-token', 'credentials token');
};

# ============================================================================
# Constructor with pre-built objects
# ============================================================================

subtest 'new with server/credentials objects' => sub {
    my $server = Kubernetes::REST::Server->new(endpoint => 'https://obj.local:6443');
    my $creds  = Kubernetes::REST::AuthToken->new(token => 'obj-token');

    my $kube = Net::Async::Kubernetes->new(
        server      => $server,
        credentials => $creds,
    );
    is($kube->server, $server, 'server object passed through');
    is($kube->credentials, $creds, 'credentials object passed through');
};

# ============================================================================
# Accessors and defaults
# ============================================================================

subtest 'accessors and defaults' => sub {
    my $kube = Net::Async::Kubernetes->new(
        server      => { endpoint => 'https://test.local' },
        credentials => { token => 'x' },
    );

    is($kube->kubeconfig, undef, 'kubeconfig defaults to undef');
    is($kube->context, undef, 'context defaults to undef');
    is($kube->resource_map, undef, 'resource_map defaults to undef');
    is($kube->resource_map_from_cluster, 0, 'resource_map_from_cluster defaults to 0');
};

# ============================================================================
# resource_map passthrough
# ============================================================================

subtest 'resource_map passed to constructor' => sub {
    my %map = (Foo => '+My::Foo');
    my $kube = Net::Async::Kubernetes->new(
        server       => { endpoint => 'https://test.local' },
        credentials  => { token => 'x' },
        resource_map => \%map,
    );
    is_deeply($kube->resource_map, \%map, 'resource_map stored');
};

# ============================================================================
# Missing server/credentials
# ============================================================================

subtest 'no config and no auto-detection' => sub {
    # Force auto-detection to fail: fake HOME, no KUBECONFIG, no SA token
    local $ENV{HOME} = '/nonexistent';
    local $ENV{KUBECONFIG};
    delete $ENV{KUBECONFIG};
    my $kube = Net::Async::Kubernetes->new;
    eval { $kube->server };
    like($@, qr/server or kubeconfig required/, 'server croaks without config');

    eval { $kube->credentials };
    like($@, qr/credentials or kubeconfig required/, 'credentials croaks without config');
};

# ============================================================================
# kubeconfig loading (against a fixture, never the running system's config)
# ============================================================================

# A kubeconfig test must not read the kubeconfig of the machine it runs on.
# Even a perfectly valid foreign config is no basis for a test: it may use an
# exec auth plugin, name an unreachable cluster or an unusual cert setup, and
# a degenerate one takes the whole run down (GitHub issue #1). Everything below
# runs against fixtures in a throwaway HOME instead.

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

subtest 'new with kubeconfig' => sub {
    my ($home, $path) = kubeconfig_fixture(<<'YAML');
apiVersion: v1
kind: Config
clusters:
  - name: fixture-cluster
    cluster:
      server: https://k8s.fixture.local:6443
      insecure-skip-tls-verify: true
contexts:
  - name: fixture-context
    context:
      cluster: fixture-cluster
      user: fixture-user
current-context: fixture-context
users:
  - name: fixture-user
    user:
      token: fixture-token
YAML

    # Both variables point at the fixture, so neither the explicit path nor any
    # indirect resolution (KUBECONFIG, ~/.kube/config) can reach the config of
    # the machine running the test.
    local $ENV{HOME} = "$home";
    local $ENV{KUBECONFIG} = $path;

    my $kube = Net::Async::Kubernetes->new(kubeconfig => $path);
    ok($kube->server, 'server resolved from kubeconfig');
    isa_ok($kube->server, 'Kubernetes::REST::Server');
    is($kube->server->endpoint, 'https://k8s.fixture.local:6443',
        'endpoint from fixture cluster');
    ok($kube->credentials, 'credentials resolved from kubeconfig');
    is($kube->credentials->token, 'fixture-token', 'token from fixture user');
};

subtest 'degenerate kubeconfig croaks instead of killing the run' => sub {
    # The config from GitHub issue #1: written by tooling that never reached a
    # cluster, so it has no clusters, contexts or users at all. An explicitly
    # passed kubeconfig must resolve or croak (Net::Async::Kubernetes::configure
    # deliberately does not eval it), and that croak has to stay catchable.
    my ($home, $path) = kubeconfig_fixture(<<'YAML');
apiVersion: v1
clusters: null
contexts: null
current-context: ""
kind: Config
preferences: {}
users: null
YAML

    local $ENV{HOME} = "$home";
    local $ENV{KUBECONFIG} = $path;

    # Matched loosely on purpose: what is asserted here is that the failure
    # arrives as a catchable, diagnosable exception about resolving the
    # kubeconfig - not the exact wording of Kubernetes::REST, which is being
    # reworded separately.
    throws_ok {
        Net::Async::Kubernetes->new(kubeconfig => $path)
    } qr/context|kubeconfig/i, 'degenerate kubeconfig croaks, catchably';
};

# ============================================================================
# _rest lazy builder
# ============================================================================

subtest '_rest lazy init' => sub {
    my $kube = Net::Async::Kubernetes->new(
        server      => { endpoint => 'https://test.local' },
        credentials => { token => 'test' },
    );
    my $rest = $kube->_rest;
    isa_ok($rest, 'Kubernetes::REST');
    is($rest->server->endpoint, 'https://test.local', '_rest has correct server');
};

# ============================================================================
# expand_class delegation
# ============================================================================

subtest 'expand_class delegates to _rest' => sub {
    my $kube = Net::Async::Kubernetes->new(
        server      => { endpoint => 'https://test.local' },
        credentials => { token => 'test' },
        resource_map_from_cluster => 0,
    );
    my $class = $kube->expand_class('Pod');
    like($class, qr/Pod/, 'expand_class resolves Pod');
};

# ============================================================================
# Custom resource_map in expand_class
# ============================================================================

subtest 'expand_class with custom resource_map' => sub {
    # Need to load the CRD class first
    eval {
        require IO::K8s;
        my $default_map = IO::K8s->default_resource_map;
        my $kube = Net::Async::Kubernetes->new(
            server      => { endpoint => 'https://test.local' },
            credentials => { token => 'test' },
            resource_map => {
                %$default_map,
                MyCustomThing => '+My::Custom::Thing',
            },
            resource_map_from_cluster => 0,
        );
        my $class = $kube->expand_class('MyCustomThing');
        is($class, 'My::Custom::Thing', 'custom resource_map entry resolved');
    };
    skip "IO::K8s default_resource_map not available", 1 if $@;
};

done_testing;
