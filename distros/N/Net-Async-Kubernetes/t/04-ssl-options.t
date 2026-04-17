use strict;
use warnings;
use Test::More;

use IO::Socket::SSL;
use Net::Async::Kubernetes;
use Kubernetes::REST::Server;
use Kubernetes::REST::AuthToken;

# ============================================================================
# SSL options with full config
# ============================================================================

subtest 'ssl options with all certs' => sub {
    my $kube = Net::Async::Kubernetes->new(
        server => Kubernetes::REST::Server->new(
            endpoint          => 'https://k8s.local:6443',
            ssl_verify_server => 1,
            ssl_ca_file       => '/path/to/ca.crt',
            ssl_cert_file     => '/path/to/client.crt',
            ssl_key_file      => '/path/to/client.key',
        ),
        credentials => Kubernetes::REST::AuthToken->new(token => 'test'),
    );

    my @opts = $kube->_ssl_options;
    my %opts = @opts;

    is($opts{SSL_verify_mode}, SSL_VERIFY_PEER, 'SSL_verify_mode is VERIFY_PEER');
    is($opts{SSL_ca_file}, '/path/to/ca.crt', 'SSL_ca_file passed through');
    is($opts{SSL_cert_file}, '/path/to/client.crt', 'SSL_cert_file passed through');
    is($opts{SSL_key_file}, '/path/to/client.key', 'SSL_key_file passed through');
};

# ============================================================================
# SSL with verify disabled
# ============================================================================

subtest 'ssl options with verify disabled' => sub {
    my $kube = Net::Async::Kubernetes->new(
        server => Kubernetes::REST::Server->new(
            endpoint          => 'https://k8s.local:6443',
            ssl_verify_server => 0,
        ),
        credentials => Kubernetes::REST::AuthToken->new(token => 'test'),
    );

    my %opts = $kube->_ssl_options;
    is($opts{SSL_verify_mode}, SSL_VERIFY_NONE, 'SSL_verify_mode is VERIFY_NONE');
    ok(!exists $opts{SSL_ca_file}, 'no SSL_ca_file when not set');
    ok(!exists $opts{SSL_cert_file}, 'no SSL_cert_file when not set');
    ok(!exists $opts{SSL_key_file}, 'no SSL_key_file when not set');
};

# ============================================================================
# SSL with only CA cert
# ============================================================================

subtest 'ssl options with only CA cert' => sub {
    my $kube = Net::Async::Kubernetes->new(
        server => Kubernetes::REST::Server->new(
            endpoint          => 'https://k8s.local:6443',
            ssl_verify_server => 1,
            ssl_ca_file       => '/path/to/ca.crt',
        ),
        credentials => Kubernetes::REST::AuthToken->new(token => 'test'),
    );

    my %opts = $kube->_ssl_options;
    is($opts{SSL_verify_mode}, SSL_VERIFY_PEER, 'verify enabled');
    is($opts{SSL_ca_file}, '/path/to/ca.crt', 'CA file set');
    ok(!exists $opts{SSL_cert_file}, 'no client cert');
    ok(!exists $opts{SSL_key_file}, 'no client key');
};

# ============================================================================
# SSL with inline PEM data
# ============================================================================

subtest 'ssl options with inline pem data' => sub {
    my $kube = Net::Async::Kubernetes->new(
        server => Kubernetes::REST::Server->new(
            endpoint          => 'https://k8s.local:6443',
            ssl_verify_server => 1,
            ssl_ca_pem        => "CA-PEM\n",
            ssl_cert_pem      => "CERT-PEM\n",
            ssl_key_pem       => "KEY-PEM\n",
        ),
        credentials => Kubernetes::REST::AuthToken->new(token => ''),
    );

    my %opts = $kube->_ssl_options;
    is($opts{SSL_verify_mode}, SSL_VERIFY_PEER, 'verify enabled for pem config');
    ok($opts{SSL_ca_file}, 'CA pem materialized to temp file');
    ok($opts{SSL_cert_file}, 'client cert pem materialized to temp file');
    ok($opts{SSL_key_file}, 'client key pem materialized to temp file');
    is(do { local (@ARGV, $/) = $opts{SSL_ca_file}; <> }, "CA-PEM\n", 'CA pem contents preserved');
    is(do { local (@ARGV, $/) = $opts{SSL_cert_file}; <> }, "CERT-PEM\n", 'client cert pem contents preserved');
    is(do { local (@ARGV, $/) = $opts{SSL_key_file}; <> }, "KEY-PEM\n", 'client key pem contents preserved');
};

# ============================================================================
# SSL options are cached
# ============================================================================

subtest 'ssl options cached' => sub {
    my $kube = Net::Async::Kubernetes->new(
        server => Kubernetes::REST::Server->new(
            endpoint          => 'https://k8s.local:6443',
            ssl_verify_server => 1,
            ssl_ca_file       => '/path/to/ca.crt',
        ),
        credentials => Kubernetes::REST::AuthToken->new(token => 'test'),
    );

    my @opts1 = $kube->_ssl_options;
    my @opts2 = $kube->_ssl_options;
    is_deeply(\@opts1, \@opts2, 'ssl options consistent across calls');
};

done_testing;
