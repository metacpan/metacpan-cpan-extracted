package Net::ACME2::HTTP::Convert;

use strict;
use warnings;

use HTTP::Tiny::UA::Response ();

use Net::ACME2::X ();

sub http_tiny_to_net_acme2 {
    my ($method, $resp) = @_;

    my $resp_obj = HTTP::Tiny::UA::Response->new($resp);

    #cf. HTTP::Tiny docs
    if ( $resp_obj->status() == 599 ) {
        die Net::ACME2::X->create(
            'HTTP::Network',
            {
                method    => $method,
                url       => $resp_obj->url(),
                error     => $resp_obj->content(),
                redirects => $resp->{'redirects'},
            }
        );
    }

    if ( $resp->{'status'} >= 400 ) {
        die Net::ACME2::X->create(
            'HTTP::Protocol',
            {
                method    => $method,
                redirects => $resp->{'redirects'},
                ( map { ( $_ => $resp_obj->$_() ) } qw( content status reason url headers ) ),
            },
        );
    }

    return $resp_obj;
}

1;
