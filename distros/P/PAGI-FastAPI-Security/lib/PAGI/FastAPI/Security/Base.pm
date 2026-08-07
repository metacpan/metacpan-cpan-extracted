package PAGI::FastAPI::Security::Base;

use v5.36;
use version;
use Carp qw(croak);
use Future::AsyncAwait;
use PAGI::FastAPI::Depends qw(Depends);

our $VERSION   = qv('v0.0.4');
our $AUTHORITY = 'cpan:MANWAR';

=encoding utf-8

=head1 NAME

PAGI::FastAPI::Security::Base - Internal base class for PAGI::FastAPI::Security schemes

=head1 VERSION

Version v0.0.4

=head1 DESCRIPTION

Main usage. This will provide you with the common C<depends()> wiring and
401/403 failure helpers on which L<PAGI::FastAPI::Security::HTTPBearer>,
L<PAGI::FastAPI::Security::HTTPBasic>, L<PAGI::FastAPI::Security::APIKey>,
and L<PAGI::FastAPI::Security::OAuth2::PasswordBearer> are based.

Concrete classes will have to implemente C<_extract($c)>,
which will have to return extracted credential value/structure on success,
or C<undef> on failure.

=cut

sub new ($class, %opts) {
    croak "$class is abstract; use a concrete scheme subclass" if $class eq __PACKAGE__;
    return bless {
        auto_error => $opts{auto_error} // 1,
        %opts,
    }, $class;
}

=head2 C<depends(%opts)>

Returns a L<PAGI::FastAPI::Depends> object suitable for a route's
C<dependencies> list. C<%opts> supports the same C<key> option as
C<Depends()> itself.

    dependencies => [ $scheme->depends(key => 'token') ],

=cut

sub depends ($self, %opts) {
    return Depends(
        async sub ($c) { return $self->_run($c) },
        %opts,
    );
}

# Shared execution wrapper: calls the subclass's _extract(), and on
# failure applies the standard auto_error behaviour (set $c->status(...)
# to a value >= 400 and return a body hash), which is the actual failure
# contract PAGI::FastAPI's dispatcher checks for.
sub _run ($self, $c) {
    my $value = $self->_extract($c);
    return $value if defined $value;

    return undef unless $self->{auto_error};

    my ($status, $detail, @headers) = $self->_failure;
    $c->status($status);
    $c->set_header(@$_) for @headers;
    return { detail => $detail };
}

# Default failure: 403 Forbidden, no challenge header. Bearer/Basic/OAuth2
# override this to send a 401 + WWW-Authenticate challenge instead, per
# RFC 7235 / RFC 6750.
sub _failure ($self) {
    return (403, 'Not authenticated');
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

    perldoc PAGI::FastAPI::Security::Base

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

1; # End of PAGI::FastAPI::Security::Base
