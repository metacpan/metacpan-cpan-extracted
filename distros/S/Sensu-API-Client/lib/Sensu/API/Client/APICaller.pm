package Sensu::API::Client::APICaller;
$Sensu::API::Client::APICaller::VERSION = '0.02';
use 5.010;
use Moo::Role;

use Carp;
use JSON;
use HTTP::Tiny;

our @CARP_NOT = qw/ Sensu::API::Client /;

has ua => (
    is  => 'ro',
    default => sub { HTTP::Tiny->new },
);

has headers => (
    is => 'ro',
    default => sub { {
        'Accept'        => 'application/json',
        'Content-type'  => 'application/json',
    }; },
);

sub get {
    my ($self, $url) = @_;
    my $r = $self->ua->get($self->url . $url, { headers => $self->headers });
    croak "$r->{status} $r->{reason}" unless $r->{success};

    return $r->{content} ? decode_json($r->{content}) : 1;
}

sub post {
    my ($self, $url, $body) = @_;
    my $post = { headers => $self->headers };
    if (defined $body) {
        $post->{content} = encode_json($body);
    } else {
        $post->{headers}->{'Content-Length'} = '0';
    }

    my $r = $self->ua->post($self->url . $url, $post);
    croak "$r->{status} $r->{reason}" unless $r->{success};

    return decode_json($r->{content});
}

sub delete {
    my ($self, $url) = @_;
    my $r = $self->ua->delete($self->url . $url, { headers => $self->headers });
    croak "$r->{status} $r->{reason}" unless $r->{success};
    return;
}

1;
