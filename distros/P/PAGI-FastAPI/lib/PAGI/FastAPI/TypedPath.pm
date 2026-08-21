package PAGI::FastAPI::TypedPath;

use v5.38;
use version;

our $VERSION   = qv('v1.2.4');
our $AUTHORITY = 'cpan:MANWAR';

use Exporter 'import';
use Future::AsyncAwait;
use PAGI::FastAPI::Depends qw(Depends);

our @EXPORT_OK = qw(TypedPath);

# Path parameters are captured via regex ([^/]+) and land in Context as
# plain strings, unconditionally, there is no coercion step at the
# routing layer itself.
#
# What per-route 'dependencies' DOES already give us is a genuine extension
# point, executed in order against $c before the handler runs, using this
# exact contract (read directly from PAGI::FastAPI's own
# dependency-execution loop):
#
#   my $dep_res = await $dep->{code}->($c);
#   if ($c->status >= 400) { return $dep_res // {...}; }   # short-circuits
#   if (defined $dep->{key} && defined $dep_res) {
#       $c->stash->{$dep->{key}} = $dep_res;               # otherwise stashed
#   }
#
# TypedPath() builds a Depends()-compatible coderef against that exact
# contract: on failure it sets $c->status(422) and returns a body (which
# the dependency loop above will use verbatim, short-circuiting the
# handler), on success it returns the COERCED value, so if you give it a
# `key`, the typed value lands in $c->stash->{$key} for your handler to
# read, rather than making you re-parse $c->path_param() yourself.





# TypedPath($param_name, $type) -> a coderef of async sub ($c) {...},
# meant to be passed to Depends(), e.g.:
#
#   dependencies => [ Depends(TypedPath('item_id', Int), key => 'item_id') ]
#
# $type must be a Type::Tiny object/constraint (the same convention core
# uses for 'query'/'body').
sub TypedPath ($param_name, $type) {
    return async sub ($c) {
        my $raw = $c->path_param($param_name);

        if (my $err = $type->validate($raw)) {
            $c->status(422);
            return { detail => "Path parameter '$param_name' invalid: $err" };
        }

        # Coerce if the type supports it (e.g. Types::Standard's Int
        # doesn't numify a string automatically on ->validate, validate
        # only checks, it doesn't transform). If the type is coercible
        # (has_coercion) and provides ->coerce, use the coerced value;
        # otherwise return the raw (already-validated) string as-is. This
        # means plain Types::Standard::Int will validate that "42" LOOKS
        # like an integer but still hand back the string "42", not the
        # number 42, pass a coercing type (e.g. Type::Tiny's ->plus_coercions
        # or Types::Standard::Int->coercibly) if you need a real Perl
        # integer, not just a validated string.
        if ($type->can('has_coercion')
            && $type->has_coercion
            && $type->can('coerce')) {
            return $type->coerce($raw);
        }

        return $raw;
    };
}

=encoding utf-8

=head1 NAME

PAGI::FastAPI::TypedPath - Path Parameter Validation for PAGI::FastAPI

=head1 VERSION

Version v1.2.4

=head1 SYNOPSIS

    use PAGI::FastAPI::Depends qw(Depends);
    use PAGI::FastAPI::TypedPath qw(TypedPath);
    use Types::Standard qw(Int);

    $app->get('/items/{item_id}',
        dependencies => [
            Depends(TypedPath('item_id', Int), key => 'item_id'),
        ],
        handler => async sub ($c) {
            my $item_id = $c->stash->{item_id};   # validated
            return { item_id => $item_id };
        }
    );

    # Invalid input (e.g. GET /items/abc) never reaches the handler --
    # the dependency short-circuits with 422 automatically, the same way
    # core's own query/body validation does.

=head1 DESCRIPTION

Python FastAPI infers a path parameter's type from your function signature
(e.g. C<item_id: int>) and rejects non-matching requests with a C<422>
automatically. C<PAGI::FastAPI> doesn't have an equivalent at the routing
layer, path parameters always arrive as plain strings. C<TypedPath()>
reproduces the validate-and-422-automatically behaviour by building a
coderef compatible with C<Depends()>, so it plugs into the exact same
dependency short-circuit mechanism core already uses for C<query>/C<body>
validation failures (confirmed against the real dependency-execution loop
in C<PAGI::FastAPI>'s source).

B<Validation vs. coercion:> C<< $type->validate($raw) >> (what
L<Type::Tiny> does by default) checks that the string looks right but
doesn't transform it, a plain C<Types::Standard::Int> will accept
C<"42"> but still hand back the I<string> C<"42">, not the Perl integer
C<42>. If you need an actual coerced value, pass a type with coercion
enabled (e.g. via L<Type::Tiny>'s C<plus_coercions>), and C<TypedPath()>
will use C<< ->coerce >> automatically when C<< ->has_coercion >> is true.

=head1 FUNCTIONS

=head2 C<TypedPath($param_name, $type)>

Returns a coderef of C<< async sub ($c) {...} >> suitable for passing
directly to C<Depends()>. C<$type> must be a L<Type::Tiny> object.

On validation failure: sets C<< $c->status(422) >> and returns
C<< { detail => "Path parameter '$param_name' invalid: $err" } >>, which
(via core's own dependency-execution loop) short-circuits before your
handler runs.

On success: returns the (optionally coerced) value. Pass C<key =E<gt> ...>
to C<Depends()> to have it land in C<< $c->stash->{...} >>.

=head1 CAVEATS

This validates AFTER routing has already matched the request to a route
using the raw, untyped C<{param}> capture, it cannot be used to
distinguish between two routes based on a path segment's type (e.g.
C</items/{id}> where C<id> must be numeric vs. a separate literal route).
That level of route-matching-time type dispatch would require a change to
the router itself, not just a dependency.

=head1 SEE ALSO

L<PAGI::FastAPI::Depends>, L<Type::Tiny>, L<Types::Standard>

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

    perldoc PAGI::FastAPI::TypedPath

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

1; # End of PAGI::FastAPI::TypedPath
