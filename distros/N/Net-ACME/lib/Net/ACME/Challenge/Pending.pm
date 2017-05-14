package Net::ACME::Challenge::Pending;

=encoding utf-8

=head1 NAME

Net::ACME::Challenge::Pending - base class for an unhandled challenge

=head1 DESCRIPTION

This base class encapsulates behavior to respond to unhandled challenges.
To work with challenges that have been handled (successfully or not),
see C<Net::ACME::Challenge>.

Note that HTTP requests have some “helper” logic in the subclass
C<Net::ACME::Challenge::Pending::http_01>.

=cut

use strict;
use warnings;

use Net::ACME::Utils ();

sub new {
    my ( $class, %opts ) = @_;

    Net::ACME::Utils::verify_token( $opts{'token'} );

    return bless { map { ( "_$_" => $opts{$_} ) } qw(type token uri) }, $class;
}

sub token {
    my ($self) = @_;
    return $self->{'_token'};
}

sub uri {
    my ($self) = @_;
    return $self->{'_uri'};
}

sub type {
    my ($self) = @_;
    return $self->{'_type'};
}

sub make_key_authz {
    my ( $self, $jwk ) = @_;

    my $jwk_thumbprint = Net::ACME::Utils::get_jwk_thumbprint($jwk);

    return "$self->{'_token'}.$jwk_thumbprint";
}

1;
