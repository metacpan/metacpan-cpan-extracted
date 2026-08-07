package PAGI::FastAPI::Security::OAuth2::PasswordBearer;

use v5.36;
use version;
use Carp qw(croak);
use parent 'PAGI::FastAPI::Security::Base';

our $VERSION   = qv('v0.0.4');
our $AUTHORITY = 'cpan:MANWAR';

=encoding utf-8

=head1 NAME

PAGI::FastAPI::Security::OAuth2::PasswordBearer - OAuth2 password-bearer scheme for PAGI::FastAPI

=head1 VERSION

Version v0.0.4

=head1 SYNOPSIS

    use PAGI::FastAPI::Security::OAuth2::PasswordBearer;

    my $oauth2 = PAGI::FastAPI::Security::OAuth2::PasswordBearer->new(
        token_url => '/token',
        scopes    => { 'items:read' => 'Read items', 'items:write' => 'Write items' },
    );

    $app->get('/items',
        dependencies => [ $oauth2->depends(key => 'token') ],
        handler      => async sub ($c) {
            my $token = $c->stash->{token};
            # ... verify $token yourself (e.g. Crypt::JWT) and check scopes ...
            return { items => [] };
        },
    );

=head1 DESCRIPTION

One can find similarities in this with what C<OAuth2PasswordBearer> of the
Python FastAPI does. It retrieves the bearer token from the C<Authorization>
header, just like L<PAGI::FastAPI::Security::HTTPBearer> does, and extracts
the OAuth2 C<token_url>/C<scopes> metadata.

The statement B<The specific task of this class does not involve implementing
an OAuth2 token endpoint, authorization code flow, or token verification.> It's
a data extraction process, just like C<fastapi.security.OAuth2PasswordBearer>
does too.

The actual token issuance and verification are left to you or a dedicated
OAuth2 server module.

=head1 CONSTRUCTOR OPTIONS

=over 4

=item * C<token_url> - B<Required>. The path clients should POST
credentials to in order to obtain a token (informational metadata only;
not implemented by this class).

=item * C<scopes> - (Optional) HashRef of C<< scope => description >>
pairs, for future OpenAPI documentation.

=item * C<auto_error> - (Optional) See L<PAGI::FastAPI::Security::Base>.
Default: true.

=back

=cut

sub new ($class, %opts) {
    croak "OAuth2::PasswordBearer requires a 'token_url' option"
        unless defined $opts{token_url} && length $opts{token_url};
    $opts{scopes} //= {};

    return $class->SUPER::new(%opts);
}

=head2 C<token_url()>

Returns the configured token URL.

=cut

sub token_url ($self) { $self->{token_url} }

=head2 C<scopes()>

Returns the configured scopes HashRef.

=cut

sub scopes ($self) { $self->{scopes} }

sub _extract ($self, $c) {
    my $auth = $c->header('Authorization') // return undef;
    return undef unless $auth =~ /^Bearer\s+(\S+)$/i;
    return $1;
}

sub _failure ($self) {
    return (401, 'Not authenticated', ['WWW-Authenticate' => 'Bearer']);
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

    perldoc PAGI::FastAPI::Security::OAuth2::PasswordBearer

You can also look for information at:

=over 4

=item * BUG Report

L<https://github.com/manwar/PAGI-FastAPI-Security/issues>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/PAGI-FastAPI-Security>

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

1; # End of PAGI::FastAPI::Security::OAuth2::PasswordBearer
