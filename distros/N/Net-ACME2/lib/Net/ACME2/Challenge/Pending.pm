package Net::ACME2::Challenge::Pending;

=encoding utf-8

=head1 NAME

Net::ACME2::Challenge::Pending - base class for an unhandled challenge

=head1 DESCRIPTION

This base class encapsulates behavior to respond to unhandled challenges.
To work with challenges that have been handled (successfully or not),
see C<Net::ACME2::Challenge>.

Note that HTTP requests have some “helper” logic in the subclass
C<Net::ACME2::Challenge::Pending::http_01>.

=cut

use strict;
use warnings;

use Net::ACME::Utils ();

use parent qw( Net::ACME2::AccessorBase );

use constant _ACCESSORS => (
    'token',
    'uri',
    'type',
);

sub new {
    my ( $class, %opts ) = @_;

    #Net::ACME::Utils::verify_token( $opts{'token'} );

    return bless { map { ( "_$_" => $opts{$_} ) } qw(type token uri) }, $class;
}

1;
