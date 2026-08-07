package PAGI::FastAPI::Context;

use v5.36;
use version;

our $VERSION   = qv('v0.0.5');
our $AUTHORITY = 'cpan:MANWAR';

=encoding utf-8

=head1 NAME

PAGI::FastAPI::Context - Request and Response Lifecycle Context for PAGI::FastAPI

=head1 VERSION

Version v0.0.5

=head1 SYNOPSIS

    # Inspecting Request Parameters
    my $user_id = $c->path_param('id');
    my $limit   = $c->query_param('limit');
    my $name    = $c->body('name');

    # Generic Parameter Fallback (Path -> Query -> Body)
    my $token   = $c->param('token');

    # Headers & Scope
    my $ua      = $c->header('User-Agent');
    my $scope   = $c->scope;

    # Stash Storage
    $c->stash->{user} = { id => 42, role => 'admin' };

    # Modifying Response State
    $c->status(201);
    $c->set_header('X-Custom-Header' => 'value');

=head1 DESCRIPTION

C<PAGI::FastAPI::Context> encapsulates the request environment, parsed parameters,
payload data, and response state for an individual HTTP exchange processed
by L<PAGI::FastAPI>.

An instance of this context is passed as the primary argument to route handlers,
middleware functions, and dependency blocks.

=head1 METHODS

=head2 C<new(%args)>

Constructor called internally by L<PAGI::FastAPI>. Accepts:

=over 4

=item * C<scope> - PAGI environment HashRef.

=item * C<query_params> - HashRef of validated query parameters.

=item * C<path_params> - HashRef of route path variables.

=item * C<body> - Decoded payload body (HashRef, ArrayRef, or Scalar).

=item * C<status> - Initial HTTP response code (default: C<200>).

=item * C<res_headers> - Initial response headers ArrayRef (default: C<[]>).

=item * C<stash> - Context-bound storage HashRef (default: C<{}>).

=back

=cut

sub new ($class, %args) {
    return bless {
        scope        => $args{scope}        // {},
        query_params => $args{query_params} // {},
        path_params  => $args{path_params}  // {},
        body         => $args{body},
        status       => $args{status}       // 200,
        res_headers  => $args{res_headers}  // [],
        stash        => $args{stash}        // {},
    }, $class;
}

=head2 C<scope()>

Returns the raw PAGI scope HashRef for the current request.

=cut

sub scope ($self) { $self->{scope} }

=head2 C<status([ $code ])>

Gets or sets the HTTP status code for the response.

    $c->status(403);
    my $code = $c->status; # 403

=cut

sub status ($self, $val = undef) {
    if (defined $val) {
        $self->{status} = $val;
    }
    return $self->{status};
}

=head2 C<res_headers()>

Returns the current list of outgoing response header pairs as an ArrayRef of
tuple pairs C<[ [$name, $val], ... ]>.

=cut

sub res_headers ($self) { $self->{res_headers} }

=head2 C<set_header($key, $val)>

Appends an outgoing HTTP header pair to the response headers list.

    $c->set_header('X-Frame-Options' => 'DENY');

=cut

sub set_header ($self, $key, $val) {
    push @{$self->{res_headers}}, [$key, $val];
}

=head2 C<header($name)>

Case-insensitively searches incoming request headers (from C<< $c->scope->{headers} >>)
and returns its scalar value, or C<undef> if missing.

    my $auth = $c->header('Authorization');

=cut

sub header ($self, $name) {
    my $headers = $self->{scope}{headers} // [];
    my $lc_name = lc($name);
    for my $h (@$headers) {
        return $h->[1] if lc($h->[0]) eq $lc_name;
    }
    return undef;
}

=head2 C<path_params()>

Returns the HashRef containing all parsed path parameters.

=cut

sub path_params ($self) { $self->{path_params} }

=head2 C<path_param($key)>

Returns a specific parsed path parameter by name, or C<undef> if absent.

=cut

sub path_param ($self, $name) {
    return $self->{path_params}{$name};
}

=head2 C<query_params()>

Returns the HashRef containing all parsed query parameters.

=cut

sub query_params ($self) { $self->{query_params} }

=head2 C<query_param($key)>

Returns a specific parsed query parameter by name, or C<undef> if absent.

=cut

sub query_param ($self, $name) {
    return $self->{query_params}{$name};
}

=head2 C<body([ $key ])>

If called without parameters, returns the full raw/decoded request body.

If called with a C<$key> parameter and the body is a HashRef, returns the
value for that key, or C<undef> if missing or if the body is not a HashRef.

    my $full_body = $c->body;
    my $user_name = $c->body('username');

=cut

sub body ($self, $key = undef) {
    if (defined $key) {
        return (ref $self->{body} eq 'HASH') ? $self->{body}{$key} : undef;
    }
    return $self->{body};
}

=head2 C<param($key)>

Convenience parameter accessor that checks parameter stores in priority order:

1. Path parameters (C<path_param>)
2. Query parameters (C<query_param>)
3. JSON/Body fields (C<body($key)>)

Returns the first matching non-undef value, or C<undef> if the key is not
present in any store.

=cut

# General parameter lookup (checks path -> query -> body in order)
sub param ($self, $key) {
    return $self->path_param($key)
        // $self->query_param($key)
        // $self->body($key);
}

=head2 C<stash()>

Returns a HashRef tied to the lifecycle of this context. Useful for sharing
data between middleware, dependency injection blocks, and final route
handlers.

    $c->stash->{db_session} = $db;

=cut

sub stash ($self) { $self->{stash} }

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

    perldoc PAGI::FastAPI::Context

You can also look for information at:

=over 4

=item * BUG Report

L<https://github.com/manwar/PAGI-FastAPI/issues>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/PAGI-FastAPI>

=item * Search MetaCPAN

L<https://metacpan.org/dist/PAGI-FastAPI/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Mohammad Sajid Anwar.

This program is free software; you can redistribute it and/or modify it under
the terms of the Artistic License (2.0). You may obtain a copy of the full
license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

=cut

1; # End of PAGI::FastAPI::Context
