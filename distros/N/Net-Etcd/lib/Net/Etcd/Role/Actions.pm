use utf8;
package Net::Etcd::Role::Actions;

use strict;
use warnings;

use Moo::Role;
use AE;
use JSON;
use MIME::Base64;
use Types::Standard qw(InstanceOf);
use AnyEvent::HTTP;
use Carp;
use Data::Dumper;

use namespace::clean;

=encoding utf8

=head1 NAME

Net::Etcd::Role::Actions

=cut

our $VERSION = '0.018';

has etcd => (
    is  => 'ro',
    isa => InstanceOf ['Net::Etcd'],
);

=head2 json_args

arguments that will be sent to the api

=cut

has json_args => ( is => 'lazy', );

sub _build_json_args {
    my ($self) = @_;
    my $args;
    for my $key ( keys %{$self} ) {
        unless ( $key =~ /(?:etcd|cb|cv|hold|json_args|endpoint)$/ ) {
            $args->{$key} = $self->{$key};
        }
    }
    return to_json($args);
}

=head2 cb

AnyEvent callback must be a CodeRef

=cut

has cb => (
    is  => 'ro',
    isa => sub {
        die "$_[0] is not a CodeRef!" if ( $_[0] && ref($_[0]) ne 'CODE')
    },
);

=head2 cv

=cut

has cv => (
    is  => 'ro',
);

=head2 init

=cut

sub init {
    my ($self)  = @_;
    my $init = $self->json_args;
    $init or return;
    return $self;
}

=head2 headers

=cut

has headers => (
    is      => 'lazy',
    clearer => 1
);

sub _build_headers {
    my ($self) = @_;
    my $headers;
    my $token = $self->etcd->auth_token;
    $headers->{'Content-Type'} = 'application/json';
    unless ( $self->endpoint =~ m/authenticate/ ) {
        $headers->{'Authorization'} = $token if $token;
    }
    return $headers;
}

has tls_ctx => ( is  => 'lazy', );

sub _build_tls_ctx {
    my ($self) = @_;
    my $cacert = $self->etcd->cacert;
    if ($cacert) {
        my $tls =({
            verify  => 0,
            ca_path => $cacert,
		});
        return $tls;
    }
    return 'low'; #default
}

=head2 hold

When set will not fire request.

=cut

has hold => ( is => 'ro' );

=head2 response

=cut

has response => ( is => 'ro' );

=head2 retry_auth

When set will retry authentication request and update token

=cut

has retry_auth => (
    is      => 'ro',
    default => 0
);

=head2 request

=cut

has request => ( is => 'lazy', );

sub _build_request {
    my ($self) = @_;
    if ($self->{retry_auth} > 1) {
        confess "Error: Unable to authenticate, check your username and password";
        $self->{retry_auth} = 0;
        return;
    }
    $self->init;
    my $cb = $self->cb;
    my $cv = $self->cv ? $self->cv : AE::cv;
    $cv->begin;

    http_request(
        'POST',
        $self->etcd->api_path . $self->{endpoint},
        headers => $self->headers,
        body => $self->json_args,
        tls_ctx => $self->tls_ctx,
        on_header => sub {
            my($headers) = @_;
            $self->{response}{headers} = $headers;
        },
        on_body   => sub {
            my ($data, $hdr) = @_;
            $self->{response}{content} = $data;
            $cb->($data, $hdr) if $cb;
            my $status = $hdr->{Status};
            $self->check_hdr($status);
            $cv->end;
            1
        },
        sub {
            my (undef, $hdr) = @_;
            #print STDERR Dumper($hdr);
            my $status = $hdr->{Status};
            $self->check_hdr($status);
            $cv->end;
        }
    );
    $cv->recv;
    $self->clear_headers;

    if ( defined $self->{retry_auth} && $self->{retry_auth} ) {
        my $auth = $self->etcd->auth()->authenticate;
        if ( $auth->{response}{success} ) {
            $self->{retry_auth} = 0;
            $self->request;
        }
    }
    return $self;
}

=head2 get_value

returns single decoded value or the first.

=cut

sub get_value {
    my ($self)   = @_;
    my $response = $self->response;
    my $content  = from_json( $response->{content} );
    #print STDERR Dumper($content);
    my $value = $content->{kvs}->[0]->{value};
    $value or return;
    return decode_base64($value);
}

=head2 all

returns list containing for example:

  {
    'mod_revision' => '3',
    'version' => '1',
    'value' => 'bar',
    'create_revision' => '3',
    'key' => 'foo0'
  }

where key and value have been decoded for your pleasure.

=cut

sub all {
    my ($self)   = @_;
    my $response = $self->response;
    my $content  = from_json( $response->{content} );
    my $kvs      = $content->{kvs};
    for my $row (@$kvs) {
        $row->{value} = decode_base64( $row->{value} );
        $row->{key}   = decode_base64( $row->{key} );
    }
    return $kvs;
}

=head2 is_success

Success is returned if the response is a 200

=cut

sub is_success {
    my ($self)   = @_;
    my $response = $self->response;
    if ( defined $response->{success} ) {
        return $response->{success};
    }
    return;
}

=head2 content

returns JSON decoded content hash

=cut

sub content {
    my ($self)   = @_;
    my $response = $self->response;
    my $content  = from_json( $response->{content} );
    return $content if $content;
    return;
}

=head2 check_hdr

check response header then define success and retry_auth.

=cut

sub check_hdr {
    my ($self, $status)   = @_;
    my $success = $status == 200 ? 1 : 0;
    $self->{response}{success} = $success;
    $self->{retry_auth}++ if $status == 401;
    return;
}

1;
