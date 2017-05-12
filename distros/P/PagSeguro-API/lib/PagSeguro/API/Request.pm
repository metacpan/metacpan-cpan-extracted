package PagSeguro::API::Request;
use Moo;

use Carp;
use LWP::UserAgent;
use PagSeguro::API::Response;

# attributes
has ua => (is => 'rw', default => sub { LWP::UserAgent->new });
has param => (is => 'rw', default => sub { {} });


# method
sub get {
    my $self = shift;
    my $args = (@_ % 2 == 0) ? {@_} : undef;

    # error (required)
    croak "url cannot be undefined" unless $args->{url};

    my $ua = $self->ua;
    my $res = $ua->get($args->{url});
    return $self->_parse_response($res);
}

sub post {
    my $self = shift;
    my $args = (@_ % 2 == 0) ? {@_} : undef;

    # error (required)
    croak "url cannot be undefined" unless $args->{url};

    my $ua = $self->ua;
    my $res = $ua->post($args->{url}, $args->{params});

    return $self->_parse_response($res);
}

sub _parse_response {
    my ($self, $res) = @_;

    my $response = PagSeguro::API::Response->new;

    if ($res->is_success) {
        $response->data($res->decoded_content);
    }
    else {
        $response->error($res->status_line);
        $response->data($res->decoded_content);
    }

    return $response;
}

1;
