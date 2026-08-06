package PAGI::FastAPI::Security;

use v5.36;
use version;

our $VERSION   = qv('v0.0.2');
our $AUTHORITY = 'cpan:MANWAR';

=encoding utf-8

=head1 NAME

PAGI::FastAPI::Security - Authentication scheme building blocks for PAGI::FastAPI

=head1 VERSION

Version v0.0.2

=head1 SYNOPSIS

    use PAGI::FastAPI;
    use PAGI::FastAPI::Security::HTTPBearer;

    my $bearer = PAGI::FastAPI::Security::HTTPBearer->new;
    my $app    = PAGI::FastAPI->new(title => 'PAGI::FastAPI app');

    $app->get('/items',
        dependencies => [ $bearer->depends(key => 'token') ],
        handler      => async sub ($c) {
            my $token = $c->stash->{token};
            # verify $token yourself, however you like
            return { items => [] };
        },
    );

=head1 DESCRIPTION

The C<PAGI::FastAPI::Security> comprises a compact selection of classes for
the authentication scheme offered as part of the L<PAGI::FastAPI::Depends>
for the framework of L<PAGI::FastAPI>, taking the inspiration from the
C<fastapi.security> module regarding the C<Python FastAPI>.

In general, every class used for the authentication scheme has been
B<extracting> the credentials from the request. The classes do provide
the specification of the error response where necessary (401 + C<WWW-Authenticate>
for the challenge-based types and 403 for the API keys). Nevertheless, they
do not really verify the credentials, and thus token signature and password/hash
verification are left to the user.

=head1 AVAILABLE SCHEMES

=over 4

=item * L<PAGI::FastAPI::Security::HTTPBearer> - C<Authorization: Bearer <token>>

=item * L<PAGI::FastAPI::Security::HTTPBasic> - C<Authorization: Basic <base64>>

=item * L<PAGI::FastAPI::Security::APIKey> - header, query, or cookie API key

=item * L<PAGI::FastAPI::Security::OAuth2::PasswordBearer> - OAuth2 bearer-token extraction + metadata

=back

=head1 DESIGN NOTES

=head2 Why these don't verify tokens

Actual token validation is quite diverse: the verification of a JWT signature
alone can refer to any of L<Crypt::JWT>, L<Mojo::JWT>, or a JWKS-fetching
client, while non-transparent tokens almost always require a database or
cache lookup. Putting together any of those is impractical because everyone
who would download this package would need to install and configure something,
and hence, following the boundaries of C exactly, all of the classes indeed
go only halfway through and leave the verification to some other external
library or the route handler.

    $app->get('/items',
        dependencies => [
            $bearer->depends(key => 'token'),
            Depends(async sub ($c) {
                my $claims = eval { verify_jwt($c->stash->{token}) };
                unless ($claims) { $c->status(401); return { detail => 'Invalid token' } }
                return $claims;
            }, key => 'claims'),
        ],
        handler => async sub ($c) { ... $c->stash->{claims} ... },
    );

=head2 Failure Contract

These classes indicate any failure in the same manner that the dependency
dispatcher of L<PAGI::FastAPI> anticipates by invoking C<< $c->status($code) >>
using a code E<gt>= 400 and by producing a body HashRef, delegating the
responsibility of the route handler generation.

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

    perldoc PAGI::FastAPI::Security

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

1; # End of PAGI::FastAPI::Security
