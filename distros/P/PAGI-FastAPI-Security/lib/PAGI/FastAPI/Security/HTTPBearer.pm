package PAGI::FastAPI::Security::HTTPBearer;

use v5.36;
use version;
use parent 'PAGI::FastAPI::Security::Base';

our $VERSION   = qv('v0.0.6');
our $AUTHORITY = 'cpan:MANWAR';

=encoding utf-8

=head1 NAME

PAGI::FastAPI::Security::HTTPBearer - HTTP Bearer token scheme for PAGI::FastAPI

=head1 VERSION

Version v0.0.6

=head1 SYNOPSIS

    use PAGI::FastAPI::Security::HTTPBearer;

    my $bearer = PAGI::FastAPI::Security::HTTPBearer->new(realm => 'my-api');

    $app->get('/items',
        dependencies => [ $bearer->depends(key => 'token') ],
        handler      => async sub ($c) {
            my $token = $c->stash->{token};   # the raw bearer token string
            # ... verify $token yourself (JWT, opaque token lookup, etc.) ...
            return { items => [] };
        },
    );

=head1 DESCRIPTION

Get the bearer token from the C<Authorization: Bearer E<lt>tokenE<gt>> request
header. This class B<does not> verify the token, it only extracts it. You will
need to combine it with your verification method (for example, L<Crypt::JWT>
for signed JWTs, or a database or cache query for opaque tokens) in your route
handler, or you will need to manage verification with another C<Depends()>.

=head1 CONSTRUCTOR OPTIONS

=over 4

=item * C<realm> - (Optional) Realm string sent in the C<WWW-Authenticate>
challenge header on failure. Default: C<'Restricted'>.

=item * C<auto_error> - (Optional) If true (this is the default value), it
automatically issues a C<401 Unauthorized> response with a C<WWW-Authenticate: Bearer>
header and returns C<{ detail => 'Not authenticated' }> when there is no valid
bearer token available, which can completely bypass the route handler. If
this is set to false, the dependency resolves as C<undef> in case of failure,
allowing optional implementation of auth.

=back

=head1 METHODS

=head2 challenge_header

    my ($key, $value) = $bearer->challenge_header;
    my ($key, $value) = $bearer->challenge_header(
        error             => 'invalid_token',
        error_description => 'The access token has expired',
    );

    # Usage inside route checks:
    $c->set_header($bearer->challenge_header(error => 'invalid_token'));

Overrides L<PAGI::FastAPI::Security::Base/challenge_header> to generate an RFC 6750
compliant C<WWW-Authenticate> challenge header for Bearer authentication schemes.

Returns a two-element array C<('WWW-Authenticate', $challenge_string)>.

=head3 OPTIONS

=over 4

=item * C<error> - (Optional) An ASCII error code as specified in RFC 6750 Section 3.1
(e.g., C<'invalid_request'>, C<'invalid_token'>, C<'insufficient_scope'>).

=item * C<error_description> - (Optional) A human-readable text providing additional
information used to assist developer troubleshooting.

=back

=head3 EXAMPLES

Without parameters:

    'WWW-Authenticate' => 'Bearer realm="Restricted"'

With error parameters:

    'WWW-Authenticate' => 'Bearer realm="Restricted", error="invalid_token", error_description="The access token has expired"'

=cut

sub new ($class, %opts) {
    $opts{realm} //= 'Restricted';
    return $class->SUPER::new(%opts);
}

sub challenge_header ($self, %args) {
    my $realm = $self->{realm};
    $realm =~ s/"/\\"/g;
    my $header = qq{Bearer realm="$realm"};

    if (my $error = $args{error}) {
        $error =~ s/"/\\"/g;
        $header .= qq{, error="$error"};
    }
    if (my $desc = $args{error_description}) {
        $desc =~ s/"/\\"/g;
        $header .= qq{, error_description="$desc"};
    }

    return ('WWW-Authenticate' => $header);
}

sub _extract ($self, $c) {
    my $auth = $c->header('Authorization') // return undef;
    return undef unless $auth =~ /^Bearer\s+(\S+)$/i;
    return $1;
}

sub _failure ($self) {
    my $realm = $self->{realm};
    $realm =~ s/"/\\"/g;
    return (401, 'Not authenticated', ['WWW-Authenticate' => qq{Bearer realm="$realm"}]);
}

=head1 AUTHOR

Mohammad Sajid Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/PAGI-FastAPI-Security>

=head1 BUGS

Please report any bugs or feature requests through the web interface at L<https://github.com/manwar/PAGI-FastAPI-Security/issues>.
I will be notified and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc PAGI::FastAPI::Security::HTTPBearer

You can also look for information at:

=over 4

=item * BUG Report

L<https://github.com/manwar/PAGI-FastAPI-Security/issues>

=item * Search MetaCPAN

L<https://metacpan.org/dist/PAGI-FastAPI-Security/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Mohammad Sajid Anwar.

This program is free software; you can redistribute it and/or modify it under
the terms of the Artistic License (2.0). You may obtain a copy of the full
license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

=cut

1; # End of PAGI::FastAPI::Security::HTTPBearer
