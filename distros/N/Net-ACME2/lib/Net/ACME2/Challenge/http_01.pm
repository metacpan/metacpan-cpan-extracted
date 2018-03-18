package Net::ACME2::Challenge::http_01;

use strict;
use warnings;

use parent qw( Net::ACME2::ChallengeBase::HasToken );

use constant PATH_DIRECTORY => '/.well-known/acme-challenge';

=encoding utf-8

=head1 NAME

Net::ACME2::Challenge::http_01

=head1 SYNOPSIS

    #e.g., “/.well-known/acme-challenge/12341243sdafdewrsvfd”
    my $path = $challenge->path();

    {
        my $handler = $challenge->create_handler( ... );

        $acme->accept_challenge($challenge);

        sleep 1 while !$acme->poll_authorization();
    }

=head1 DESCRIPTION

This module is instantiated by L<Net::ACME2::Authorization> and is a
subclass of L<Net::ACME2::Challenge>.

=head1 METHODS

=head2 I<OBJ>->create_handler( KEY_AUTHZ, DOCROOT )

Creates a file in the given DOCROOT that will, if served up normally,
satisfy ACME’s requirements for this challenge. The return value is
an object that, when DESTROYed, will remove that file.

(KEY_AUTHZ is the return of the L<Net::ACME2> instance’s
C<make_key_authorization()> method.)

This can simplify the authorization process
if you’re on the same server as all of the authorization object’s
identifiers’ HTTP document roots.

=cut

sub create_handler {
    my ($self, $key_authorization, $docroot) = @_;

    die 'need key authz!' if !$key_authorization;
    die 'need docroot!' if !length $docroot;

    my $class = (ref $self) . '::Handler';

    require Module::Load;
    Module::Load::load($class);

    return $class->new(
        key_authorization => $key_authorization,
        challenge => $self,
        document_root => $docroot,
    );
}

=head2 I<OBJ>->path()

Returns the URL path that needs to serve up the
key authorization. This is useful if, for whatever reason, you’re not
using C<create_handler()> to satisfy this challenge.

Example:

    /.well-known/acme-challenge/LoqXcYV8q5ONbJQxbmR7SCTNo3tiAXDfowyjxAjEuX0

=cut

sub path {
    my ($self) = @_;

    my $token = $self->token();

    return $self->PATH_DIRECTORY() . "/$token";
}

1;
