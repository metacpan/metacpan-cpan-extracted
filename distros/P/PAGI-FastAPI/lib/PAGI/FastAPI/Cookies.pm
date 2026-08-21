package PAGI::FastAPI::Cookies;

use v5.38;
use version;

our $VERSION   = qv('v1.2.4');
our $AUTHORITY = 'cpan:MANWAR';

use Exporter 'import';
use URI::Escape qw(uri_unescape);

our @EXPORT_OK = qw(parse_cookies cookie);

# PAGI::FastAPI::Context already exposes the raw 'Cookie' request header via
# $c->header('Cookie'), this module is pure parsing on top of that, using no
# APIs beyond the documented $c->header() accessor.
#
# Note this is READ-ONLY (parsing the incoming Cookie header). Setting
# response cookies is a separate concern, PAGI::FastAPI::Context already
# has $c->set_header/$c->add_header, so:
#
#   $c->add_header('set-cookie' => 'session=abc123; Path=/; HttpOnly');
#
# ...already works today with zero extra code; a set_cookie() sugar
# function could be added here later if the manual Set-Cookie string
# construction becomes tedious enough to be worth it.

# Parses a raw "Cookie:" header value into a plain hashref of name => value.
# Values are percent-decoded (uri_unescape); malformed pairs (no '=') are
# skipped rather than causing a die, since cookie headers are client-
# supplied and not something a server should trust to be well-formed.
sub parse_cookies ($raw_header) {
    my %cookies;
    return \%cookies unless defined $raw_header && length $raw_header;

    for my $pair (split /;\s*/, $raw_header) {
        my ($name, $value) = split /=/, $pair, 2;
        next unless defined $name && defined $value;
        $name  =~ s/^\s+|\s+$//g;
        next unless length $name;
        $cookies{$name} = uri_unescape($value);
    }

    return \%cookies;
}

# Convenience: cookie($c, 'session') instead of
# parse_cookies($c->header('Cookie'))->{session}. Re-parses the header on
# every call (cookie headers are typically small, a handful of entries, so
# this isn't a meaningful cost), if you need many cookie values in one
# request, call parse_cookies($c->header('Cookie')) once yourself instead.
sub cookie ($c, $name) {
    my $cookies = parse_cookies($c->header('Cookie'));
    return $cookies->{$name};
}

=encoding utf-8

=head1 NAME

PAGI::FastAPI::Cookies - Request Cookie Parsing Helper for PAGI::FastAPI

=head1 VERSION

Version v1.2.4

=head1 SYNOPSIS

    use PAGI::FastAPI::Cookies qw(cookie parse_cookies);

    $app->get('/whoami',
        handler => async sub ($c) {
            my $session_id = cookie($c, 'session_id');
            return { session_id => $session_id // 'none' };
        }
    );

    # Or parse once and read several values:
    $app->get('/prefs',
        handler => async sub ($c) {
            my $cookies = parse_cookies($c->header('Cookie'));
            return {
                theme => $cookies->{theme} // 'light',
                lang  => $cookies->{lang}  // 'en',
            };
        }
    );

=head1 FUNCTIONS

=head2 C<parse_cookies($raw_header)>

Parses a raw C<Cookie:> header string into a plain HashRef of
C<name =E<gt> value>. Values are percent-decoded. Returns an empty HashRef
(never C<undef>) if C<$raw_header> is undefined or empty, so callers can
safely chain C<< ->{...} >> without a definedness check.

=head2 C<cookie($c, $name)>

Convenience wrapper: C<< parse_cookies($c->header('Cookie'))->{$name} >>.
Returns C<undef> if the cookie isn't present. Re-parses the header on every
call, fine for reading one or two cookies, but call C<parse_cookies()>
once yourself if you need several values from the same request.

=head1 SETTING RESPONSE COOKIES

Not this module's concern, L<PAGI::FastAPI::Context> already supports it
directly, with zero extra code needed:

    $c->add_header('set-cookie' => 'session=abc123; Path=/; HttpOnly; SameSite=Lax');

C<add_header> (rather than C<set_header>) is important if you need to set
more than one cookie in the same response, for the same reason
L<PAGI::FastAPI::Middleware::RateLimit> uses it for stacked
C<x-ratelimit-*> headers, C<set_header> would silently overwrite an
earlier C<Set-Cookie> value instead of adding a second one.

=head1 SEE ALSO

L<PAGI::FastAPI::Context>

=head1 AUTHOR

Mohammad Sajid Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/PAGI-FastAPI>

=head1 BUGS

Please report any bugs or feature requests through the web interface at L<https://github.com/manwar/PAGI-FastAPI/issues>.
I will be notified and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc PAGI::FastAPI::Cookies

You can also look for information at:

=over 4

=item * BUG Report

L<https://github.com/manwar/PAGI-FastAPI/issues>

=item * Search MetaCPAN

L<https://metacpan.org/dist/PAGI-FastAPI/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Mohammad Sajid Anwar.

This program is free software; you can redistribute it and/or modify it under
the terms of the Artistic License (2.0).

=cut

1; # End of PAGI::FastAPI::Cookies
