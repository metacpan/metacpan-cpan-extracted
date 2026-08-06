package PAGI::FastAPI::Security::APIKey;

use v5.36;
use version;
use Carp qw(croak);
use parent 'PAGI::FastAPI::Security::Base';

our $VERSION   = qv('v0.0.2');
our $AUTHORITY = 'cpan:MANWAR';

=encoding utf-8

=head1 NAME

PAGI::FastAPI::Security::APIKey - API key authentication scheme for PAGI::FastAPI

=head1 VERSION

Version v0.0.2

=head1 SYNOPSIS

    use PAGI::FastAPI::Security::APIKey;

    # X-API-Key: <key> header
    my $api_key = PAGI::FastAPI::Security::APIKey->new(
        in   => 'header',
        name => 'X-API-Key',
    );

    # ?api_key=<key> query parameter
    my $api_key = PAGI::FastAPI::Security::APIKey->new(
        in   => 'query',
        name => 'api_key',
    );

    # api_key=<key> cookie
    my $api_key = PAGI::FastAPI::Security::APIKey->new(
        in   => 'cookie',
        name => 'api_key',
    );

    $app->get('/items',
        dependencies => [ $api_key->depends(key => 'api_key') ],
        handler      => async sub ($c) {
            my $key = $c->stash->{api_key};
            return { items => [] };
        },
    );

=head1 DESCRIPTION

Pulls the API key from the HTTP request's header, query string or some cookie,
according to the design of your API. The key verification is not done in this
class, though; you have to verify the key yourself in the route handler.

Important: Unlike query parameters declared in the route, here a query
string is read directly without the need to declare it in the route's
C<query> parameter map.

=head1 CONSTRUCTOR OPTIONS

=over 4

=item * C<in> - B<Required>. One of C<'header'>, C<'query'>, or C<'cookie'>.

=item * C<name> - B<Required>. The header/parameter/cookie name to read
the key from.

=item * C<auto_error> - (Optional) See L<PAGI::FastAPI::Security::Base>.
Default: true. Failure is a plain C<403 Forbidden> (no challenge header),
matching the convention used for API keys (there is no standard
challenge scheme for them, unlike Basic/Bearer).

=back

=cut

my %VALID_IN = map { $_ => 1 } qw(header query cookie);

sub new ($class, %opts) {
    croak "APIKey requires an 'in' option (header|query|cookie)"
        unless defined $opts{in} && $VALID_IN{$opts{in}};
    croak "APIKey requires a 'name' option"
        unless defined $opts{name} && length $opts{name};

    return $class->SUPER::new(%opts);
}

sub _extract ($self, $c) {
    my $in = $self->{in};

    if ($in eq 'header') {
        return $c->header($self->{name});
    }
    elsif ($in eq 'query') {
        return _raw_query_param($c, $self->{name});
    }
    elsif ($in eq 'cookie') {
        return _cookie($c, $self->{name});
    }
    return undef;
}

# Read directly from the raw query string rather than $c->query_param(),
# since PAGI::FastAPI only populates $c->query_params with params the
# route explicitly declared a type for, an API key shouldn't need to
# be redundantly declared on every protected route.
sub _raw_query_param ($c, $name) {
    my $qs = $c->scope->{query_string};
    return undef unless defined $qs && length $qs;

    for my $pair (split '&', $qs) {
        my ($k, $v) = split '=', $pair, 2;
        next unless defined $k;
        return _uri_unescape($v // '') if _uri_unescape($k) eq $name;
    }
    return undef;
}

sub _cookie ($c, $name) {
    my $header = $c->header('Cookie');
    return undef unless defined $header;

    for my $pair (split /;\s*/, $header) {
        my ($k, $v) = split '=', $pair, 2;
        next unless defined $k;
        return _uri_unescape($v // '') if $k eq $name;
    }
    return undef;
}

sub _uri_unescape ($str) {
    return $str unless defined $str;
    $str =~ tr/+/ /;
    $str =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/ge;
    return $str;
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

    perldoc PAGI::FastAPI::Security::APIKey

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

1; # End of PAGI::FastAPI::Security::APIKey
