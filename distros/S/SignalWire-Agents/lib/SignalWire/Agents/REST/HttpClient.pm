package SignalWire::Agents::REST::HttpClient;
use strict;
use warnings;
use Moo;

use HTTP::Tiny;
use JSON qw(encode_json decode_json);
use MIME::Base64 qw(encode_base64);

has 'project'   => ( is => 'ro', required => 1 );
has 'token'     => ( is => 'ro', required => 1 );
has 'host'      => ( is => 'ro', required => 1 );
has 'base_url'  => ( is => 'lazy' );
has '_ua'       => ( is => 'lazy' );
has '_auth_header' => ( is => 'lazy' );

sub _build_base_url {
    my ($self) = @_;
    return 'https://' . $self->host;
}

sub _build__ua {
    my ($self) = @_;
    return HTTP::Tiny->new(
        agent           => 'signalwire-agents-perl-rest/1.0',
        default_headers => {
            'Content-Type'  => 'application/json',
            'Accept'        => 'application/json',
            'Authorization' => $self->_auth_header,
        },
        timeout => 30,
    );
}

sub _build__auth_header {
    my ($self) = @_;
    my $credentials = $self->project . ':' . $self->token;
    return 'Basic ' . encode_base64($credentials, '');
}

sub _request {
    my ($self, $method, $path, %opts) = @_;
    my $url = $self->base_url . $path;

    # Add query params to URL
    if ($opts{params} && ref $opts{params} eq 'HASH' && %{$opts{params}}) {
        my @pairs;
        for my $key (sort keys %{$opts{params}}) {
            my $val = $opts{params}{$key} // '';
            push @pairs, _uri_encode($key) . '=' . _uri_encode($val);
        }
        $url .= '?' . join('&', @pairs);
    }

    my %request_opts;
    if ($opts{body}) {
        $request_opts{content} = encode_json($opts{body});
    }

    my $response = $self->_ua->request($method, $url, \%request_opts);

    unless ($response->{success}) {
        my $body = $response->{content} // '';
        my $parsed;
        eval { $parsed = decode_json($body) };
        $parsed = $body if $@;
        die SignalWire::Agents::REST::HttpClient::Error->new(
            status_code => $response->{status},
            body        => $parsed,
            url         => $path,
            method      => $method,
        );
    }

    # 204 No Content or empty body
    if ($response->{status} == 204 || !$response->{content}) {
        return {};
    }

    my $result;
    eval { $result = decode_json($response->{content}) };
    if ($@) {
        return { raw => $response->{content} };
    }
    return $result;
}

sub get {
    my ($self, $path, %opts) = @_;
    return $self->_request('GET', $path, params => $opts{params});
}

sub post {
    my ($self, $path, %opts) = @_;
    return $self->_request('POST', $path, body => $opts{body}, params => $opts{params});
}

sub put {
    my ($self, $path, %opts) = @_;
    return $self->_request('PUT', $path, body => $opts{body});
}

sub patch {
    my ($self, $path, %opts) = @_;
    return $self->_request('PATCH', $path, body => $opts{body});
}

sub delete_request {
    my ($self, $path) = @_;
    return $self->_request('DELETE', $path);
}

# Simple URI encoding
sub _uri_encode {
    my ($str) = @_;
    $str =~ s/([^A-Za-z0-9\-_.~])/sprintf("%%%02X", ord($1))/ge;
    return $str;
}

# --- Error class ---
package SignalWire::Agents::REST::HttpClient::Error;
use Moo;
use JSON qw(encode_json);

has 'status_code' => ( is => 'ro', required => 1 );
has 'body'        => ( is => 'ro', default => sub { '' } );
has 'url'         => ( is => 'ro', default => sub { '' } );
has 'method'      => ( is => 'ro', default => sub { 'GET' } );

use overload '""' => sub {
    my ($self) = @_;
    my $body = ref $self->body ? encode_json($self->body) : ($self->body // '');
    return sprintf('%s %s returned %s: %s',
        $self->method, $self->url, $self->status_code, $body);
};

1;
