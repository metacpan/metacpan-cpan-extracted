package Net::ACME2::HTTP::Response;

use strict;
use warnings;

use parent qw( HTTP::Tiny::UA::Response );

use JSON          ();

use Net::ACME2::X ();

sub die_because_unexpected {
    my ($self) = @_;

    die Net::ACME2::X->create(
        'UnexpectedResponse',
        {
            uri     => $self->url(),
            status  => $self->status(),
            reason  => $self->reason(),
            headers => $self->headers(),
        },
    );
}

#Useful for everything but certificate issuance, apparently?
sub content_struct {
    my ($self) = @_;

    my $json = ($self->{'_json'} ||= JSON->new()->allow_nonref());

    return $json->decode( $self->content() );
}

1;
