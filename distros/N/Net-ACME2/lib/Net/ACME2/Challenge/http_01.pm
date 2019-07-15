package Net::ACME2::Challenge::http_01;

use strict;
use warnings;

use parent qw( Net::ACME2::Challenge );

use constant _PATH_DIRECTORY => '/.well-known/acme-challenge';

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

=head2 I<OBJ>->create_handler( $ACME_OR_AUTHZ, $DOCROOT )

Creates a file in the given DOCROOT that will, if served up normally,
satisfy ACME’s requirements for this challenge. The return value is
an object that, when DESTROYed, will remove that file.

$ACME_OR_AUTHZ is normally a L<Net::ACME2> instance that will be used to
compute I<OBJ>’s key authorization. If you already have this authorization
(i.e., via I<OBJ>’s C<make_key_authorization()> method) you may submit
that instead. (Only that key authorization was accepted prior to version
0.28 of this distribution.)

This can simplify the authorization process
if you’re on the same server as all of the authorization object’s
identifiers’ HTTP document roots.

=cut

sub create_handler {
    my ($self, $acme_or_key_authz, $docroot) = @_;

    die 'need Net::ACME2 object or key authz!' if !$acme_or_key_authz;

    die 'need docroot!' if !length $docroot;

    my $class = __PACKAGE__ . '::Handler';

    require Module::Runtime;
    Module::Runtime::use_module($class);

    my $key_authz;

    if (ref $acme_or_key_authz) {
        $key_authz = $acme_or_key_authz->make_key_authorization($self);
    }
    else {
        $key_authz = $acme_or_key_authz;
    }

    return $class->new(
        key_authorization => $key_authz,
        challenge => $self,
        document_root => $docroot,
    );
}

#----------------------------------------------------------------------

=head2 I<OBJ>->get_path()

Returns the path component of the URL that should serve up the
relevant content. This is useful if, for whatever reason,
you’re not using C<create_handler()> to satisfy this challenge.

Example:

    /.well-known/acme-challenge/LoqXcYV8q5ONbJQxbmR7SCTNo3tiAXDfowyjxAjEuX0

=cut

sub get_path {
    my ($self) = @_;

    my $token = $self->token();

    return $self->_PATH_DIRECTORY() . "/$token";
}

# legacy - a courtesy to early adopters
*path = \*get_path;

#----------------------------------------------------------------------

=head2 I<OBJ>->get_content( $ACME )

Accepts a L<Net::ACME2> instance and returns the content that the
URL should serve.

Example:

    q1hcOY6mDLNh7jummITkoQ1PHBpaxwNwyERZEqbADqI._jDy0skz-fuLE9OyLfS2UBa9z9QtS_MZGWq3x2nMx34

=cut

sub get_content {
    my ($self, $acme) = @_;

    # Errors for the programmer.
    if (!$acme) {
        die 'Need “Net::ACME2” instance to compute HTTP content!'
    }

    return $acme->make_key_authorization($self);
}

1;
