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
use Data::Dumper;

use namespace::clean;

=encoding utf8

=head1 NAME

Net::Etcd::Role::Actions

=cut

our $VERSION = '0.009';

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
        unless ( $key =~ /(?:etcd|cb|cv|json_args|endpoint)$/ ) {
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

has headers => ( is => 'ro' );

=head2 response

=cut

has response => ( is => 'ro' );

=head2 request

=cut

has request => ( is => 'lazy', );

sub _build_request {
    my ($self) = @_;
    $self->init;
    my $cb = $self->cb;
    my $cv = $self->cv ? $self->cv : AE::cv;
    $cv->begin;
    http_request(
        'POST',
        $self->etcd->api_path . $self->{endpoint},
        headers => $self->headers,
        body => $self->json_args,
        on_header => sub {
            my($headers) = @_;
            $self->{response}{headers} = $headers;
        },
        on_body   => sub {
            my ($data, $hdr) = @_;
            $self->{response}{content} = $data;
            $cb->($data, $hdr) if $cb;
            $cv->end;
            1
        },
        sub {
            my (undef, $hdr) = @_;
            #print STDERR Dumper($hdr);
            my $status = $hdr->{Status};
            $self->{response}{success} = 1 if $status == 200;
            $cv->end;
        }
    );
    $cv->recv;
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

1;
