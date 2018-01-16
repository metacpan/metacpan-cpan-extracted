package Net::ACME::Challenge::Pending::http_01;

=encoding utf-8

=head1 NAME

Net::ACME::Challenge::Pending::http_01 - unhandled http-01 challenge

=head1 SYNOPSIS

    use Net::ACME::Challenge::Pending::http_01 ();

    my $challenge = Net::ACME::Challenge::Pending::http_01->new(

        #i.e., from the ACME new-authz call
        uri => 'https://post/url/for/challenge',
        token => 'sdgflih4we',
    );

    {
        my $handler = $challenge->create_handler(
            '/path/to/docroot',
            $jwk,    #public
        );

        #Suggest verification that the URI matches content.
        #cf. docs for Net::ACME

        my $acme = Net::ACME::SomeService->new();
        $acme->do_challenge($challenge);

        #wait until the challenge’s authz is resolved
    }

    #Once $handler goes out of scope, the filesystem preparation is undone.

=head1 DESCRIPTION

This class handles responses to C<http-01> challenges, specifically by
facilitating easy setup and teardown of proper domain control validation (DCV)
files within a given document root.

To work with challenges that have been handled (successfully or not),
see C<Net::ACME::Challenge>.

=cut

use strict;
use warnings;

use parent qw(
  Net::ACME::Challenge::Pending
);

use constant type => 'http-01';

use Net::ACME::Challenge::Pending::http_01::Handler ();

sub create_handler {
    my ( $self, $docroot, $jwk ) = @_;

    return Net::ACME::Challenge::Pending::http_01::Handler->new(
        token     => $self->token(),
        key_authz => $self->make_key_authz($jwk),
        docroot   => $docroot,
    );
}

1;
