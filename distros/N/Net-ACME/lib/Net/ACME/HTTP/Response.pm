package Net::ACME::HTTP::Response;

use strict;
use warnings;

use parent qw( HTTP::Tiny::UA::Response );

use Call::Context ();
use JSON          ();

use Net::ACME::X ();

sub die_because_unexpected {
    my ($self) = @_;

    die Net::ACME::X::create(
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

    return JSON::decode_json( $self->content() );
}

#A “poor man’s Link header parser” that only knows how to handle
#these values as described in the ACME protocol spec:
#a single “rel” parameter, and no extra whitespace.
#
#This returns key/value pairs. They should probably go into a hash,
#but I don’t see anything in the spec that says the same “rel”
#parameter can’t occur twice.
#
#If we need something more robust down the line,
#HTTP::Link::Parser::parse_single_link() may do the trick.
sub links {
    my ($self) = @_;

    Call::Context::must_be_list();

    my $links_ar = $self->header('link');
    if ( !ref $links_ar ) {
        $links_ar = [ $links_ar || () ];
    }

    my @resp;

    for my $l (@$links_ar) {
        $l =~ m/\A<([^>]+)>;rel="([^"]+)"\z/ or do {
            warn "Unrecognized link: “$l”";
            next;
        };

        push @resp, $2, $1;
    }

    return @resp;
}

1;
