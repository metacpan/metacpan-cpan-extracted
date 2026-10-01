use strict;
use warnings;
use Test::More;

use File::Temp qw(tempdir);
use MIME::Base64 qw(encode_base64);
use JSON::MaybeXS;
use HTTP::Response;
use IO::Socket::SSL;
use IO::Async::Loop;
use Net::Async::HTTP;
use Net::Async::Kubernetes;

# Characterization test: proves that inline (base64 *-data) certificates from
# a kubeconfig actually reach the SSL arguments of an outgoing HTTP request.
# Since 0.007, Net::Async::Kubernetes::_ssl_options materializes ssl_*_pem
# strings (from Kubernetes::REST::Kubeconfig's inline-cert handling) into
# File::Temp files and passes SSL_{ca,cert,key}_file to every request/connect
# call -- t/04-ssl-options.t only checks this from an already-built Server
# object, never from a kubeconfig file end to end. No MockTransport here:
# Net::Async::HTTP::do_request is intercepted directly, so nothing touches
# the network or a real TLS handshake.

my $CA_PEM   = "-----BEGIN CERTIFICATE-----\nDUMMY-CA-CERTIFICATE-DATA\n-----END CERTIFICATE-----\n";
my $CERT_PEM = "-----BEGIN CERTIFICATE-----\nDUMMY-CLIENT-CERTIFICATE-DATA\n-----END CERTIFICATE-----\n";
my $KEY_PEM  = "-----BEGIN PRIVATE KEY-----\nDUMMY-CLIENT-KEY-DATA\n-----END PRIVATE KEY-----\n";

sub slurp {
    my ($path) = @_;
    open(my $fh, '<', $path) or return undef;
    local $/;
    my $content = <$fh>;
    close $fh;
    return $content;
}

sub write_kubeconfig {
    my ($dir) = @_;
    my $path = "$dir/kubeconfig.yaml";
    open(my $fh, '>', $path) or die "cannot write $path: $!";
    print {$fh} <<"YAML";
apiVersion: v1
kind: Config
clusters:
- name: test-cluster
  cluster:
    server: https://127.0.0.1:6443
    certificate-authority-data: "@{[ encode_base64($CA_PEM, '') ]}"
contexts:
- name: test-context
  context:
    cluster: test-cluster
    user: test-user
current-context: test-context
users:
- name: test-user
  user:
    client-certificate-data: "@{[ encode_base64($CERT_PEM, '') ]}"
    client-key-data: "@{[ encode_base64($KEY_PEM, '') ]}"
YAML
    close $fh;
    return $path;
}

my $dir = tempdir(CLEANUP => 1);
my $kubeconfig_path = write_kubeconfig($dir);

my $JSON = JSON::MaybeXS->new(utf8 => 1);

subtest 'inline kubeconfig certs reach the plain HTTP request SSL options' => sub {
    my $loop = IO::Async::Loop->new;
    my $kube = Net::Async::Kubernetes->new(kubeconfig => $kubeconfig_path);
    $loop->add($kube);

    my @captured;
    my $ns;
    {
        no warnings 'redefine';
        local *Net::Async::HTTP::do_request = sub {
            my ($self, %args) = @_;
            push @captured, \%args;
            my $body = $JSON->encode({
                kind => 'Namespace', apiVersion => 'v1',
                metadata => { name => 'default' }, spec => {}, status => {},
            });
            return Future->done(
                HTTP::Response->new(200, 'OK', ['Content-Type' => 'application/json'], $body));
        };

        $ns = $kube->get('Namespace', 'default')->get;
    }

    is($ns->metadata->name, 'default', 'request round-tripped through the fake transport');
    is(scalar(@captured), 1, 'do_request was called exactly once');

    my %args = %{ $captured[0] };
    ok(exists $args{SSL_cert_file}, 'SSL_cert_file was passed');
    ok(exists $args{SSL_key_file}, 'SSL_key_file was passed');
    ok(exists $args{SSL_ca_file}, 'SSL_ca_file was passed');

    ok(-e $args{SSL_cert_file}, 'SSL_cert_file points at an existing file');
    ok(-e $args{SSL_key_file}, 'SSL_key_file points at an existing file');
    ok(-e $args{SSL_ca_file}, 'SSL_ca_file points at an existing file');

    is(slurp($args{SSL_cert_file}), $CERT_PEM,
        "cert temp file content matches kubeconfig's client-certificate-data");
    is(slurp($args{SSL_key_file}), $KEY_PEM,
        "key temp file content matches kubeconfig's client-key-data");
    is(slurp($args{SSL_ca_file}), $CA_PEM,
        "CA temp file content matches kubeconfig's certificate-authority-data");

    is($args{SSL_verify_mode}, SSL_VERIFY_PEER,
        'verify mode is PEER (insecure-skip-tls-verify not set in the kubeconfig)');
};

# The duplex path (port_forward/exec/attach) builds its websocket connection
# via _make_websocket_client()->connect(..., $self->_ssl_options), the same
# mock override point t/13-duplex-transport.t uses for its own no-network
# testing -- so the same proof is reachable here too, at reasonable cost,
# without a real socket or TLS handshake.
{
    package Test::WSClient;
    use strict;
    use warnings;
    use parent 'IO::Async::Notifier';
    use Future;

    sub configure {
        my ($self, %params) = @_;
        delete $params{$_} for qw(
            on_binary_frame on_text_frame on_close_frame
            on_read_error on_write_error on_closed
        );
        $self->SUPER::configure(%params);
    }

    sub connect {
        my ($self, %args) = @_;
        $self->{connect_args} = \%args;
        return Future->done($self);
    }

    sub connect_args { $_[0]->{connect_args} }
}

subtest 'inline kubeconfig certs reach the duplex (websocket) connect options' => sub {
    my $loop = IO::Async::Loop->new;
    my $kube = Net::Async::Kubernetes->new(kubeconfig => $kubeconfig_path);
    $loop->add($kube);

    my $last_ws;
    no warnings 'redefine';
    local *Net::Async::Kubernetes::_make_websocket_client = sub {
        my ($self, %args) = @_;
        $last_ws = Test::WSClient->new(%args);
        return $last_ws;
    };

    my $session = $kube->port_forward('Pod', 'nginx',
        namespace => 'default',
        ports     => [8080],
    )->get;

    isa_ok($session, 'Net::Async::Kubernetes::PortForwardSession');
    ok($last_ws, 'a websocket client was constructed');

    my %args = %{ $last_ws->connect_args };
    ok(exists $args{SSL_cert_file}, 'SSL_cert_file was passed to connect()');
    ok(exists $args{SSL_key_file}, 'SSL_key_file was passed to connect()');
    ok(exists $args{SSL_ca_file}, 'SSL_ca_file was passed to connect()');

    is(slurp($args{SSL_cert_file}), $CERT_PEM,
        'duplex cert temp file content matches the kubeconfig');
    is(slurp($args{SSL_key_file}), $KEY_PEM,
        'duplex key temp file content matches the kubeconfig');
    is(slurp($args{SSL_ca_file}), $CA_PEM,
        'duplex CA temp file content matches the kubeconfig');

    is($args{SSL_verify_mode}, SSL_VERIFY_PEER, 'duplex verify mode is PEER');
};

done_testing;
