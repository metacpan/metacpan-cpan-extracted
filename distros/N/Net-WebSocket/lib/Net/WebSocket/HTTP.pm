package Net::WebSocket::HTTP;

use strict;
use warnings;

use Call::Context ();

use Net::WebSocket::X ();

=encoding utf-8

=head1 NAME

Net::WebSocket::HTTP - HTTP utilities for Net::WebSocket

=head1 SYNOPSIS

    @tokens = Net::WebSocket::HTTP::split_tokens($tokens_str);

=head1 FUNCTIONS

=head2 @tokens = split_tokens( TOKENS_STR )

A parser for the C<1#token> format as defined in L<RFC 2616|https://tools.ietf.org/html/rfc2616>. (C<1#> and C<token> are defined independently of each other.)

Returns a list of the HTTP tokens in TOKENS_STR. Throws an exception
if any of the tokens is invalid as per the RFC’s C<token> definition.

=cut

#Would this be useful to publish separately? It seemed so at one point,
#but “#1token” doesn’t appear in the HTTP RFC.
sub split_tokens {
    my ($value) = @_;

    Call::Context::must_be_list();

    $value =~ s<\A[ \t]+><>;
    $value =~ s<[ \t]+\z><>;

    my @tokens;
    for my $p ( split m<[ \t]*,[ \t]*>, $value ) {
        if ($p =~ tr~()<>@,;:\\"/[]?={} \t~~) {
            die Net::WebSocket::X->create('BadToken', $p);
        }

        push @tokens, $p;
    }

    return @tokens;
}

1;
