package PAGI::FastAPI::ResponseModel;

use v5.38;
use version;

our $VERSION   = qv('v1.2.4');
our $AUTHORITY = 'cpan:MANWAR';

use Exporter 'import';
use Scalar::Util qw(blessed);
use Future::AsyncAwait;

our @EXPORT_OK = qw(with_response_model);

# There is no response_model hook in route registration itself (only 'query'
# and 'body' are validated), so this isn't a route option the way 'query'/
# 'body' are, it's a plain wrapper you apply around your own handler
# coderef, following the exact schema conventions 'body' validation already
# uses (a Type::Tiny object validating the whole value, OR a HashRef of
# field => Type::Tiny validating per-field), so it feels consistent with the
# rest of the framework rather than inventing a new schema shape.
#
# Failure semantics deliberately mirror Python FastAPI: a response failing
# its own declared response_model is treated as a SERVER bug (500), not a
# client error (422), the client didn't do anything wrong, your handler
# returned data that doesn't match what it promised. The validation detail
# is logged via warn() but not leaked to the client.

# with_response_model($schema, $handler) -> coderef suitable for the
# route's `handler` option.
#
# $schema is either:
#   - a Type::Tiny object: validates the ENTIRE returned value.
#   - a HashRef of { field => Type::Tiny }: requires the returned value to
#     be a HashRef, validates each declared field, and FILTERS the output
#     to only the declared fields (undeclared keys are silently dropped,
#     this is the actual point: it's what gives you Pydantic-style
#     response filtering, not just validation).
sub with_response_model ($schema, $handler) {
    return async sub ($c) {
        my $result = await $handler->($c);

        # Don't try to apply a response_model to a Response object (e.g.
        # PAGI::FastAPI::Response::HTML, ::SSE, or a companion ::Redirect/
        # ::File), those are already a fully-formed response, not raw
        # data for the framework to JSON-encode, so a data schema doesn't
        # apply to them.
        return $result if blessed($result) && $result->can('prepare_headers');
        return $result if blessed($result) && $result->can('dispatch');

        if (blessed($schema) && $schema->can('validate')) {
            if (my $err = $schema->validate($result)) {
                warn "[PAGI::FastAPI::ResponseModel] response_model validation failed: $err\n";
                $c->status(500);
                return { detail => 'Internal Server Error' };
            }
            return $result;
        }
        elsif (ref $schema eq 'HASH') {
            unless (ref $result eq 'HASH') {
                warn "[PAGI::FastAPI::ResponseModel] response_model expected a HashRef return value, got "
                    . (ref($result) || 'a non-reference') . "\n";
                $c->status(500);
                return { detail => 'Internal Server Error' };
            }

            for my $field (keys %$schema) {
                my $type = $schema->{$field};
                if (my $err = $type->validate($result->{$field})) {
                    warn "[PAGI::FastAPI::ResponseModel] response_model field '$field' invalid: $err\n";
                    $c->status(500);
                    return { detail => 'Internal Server Error' };
                }
            }

            # Filter: only declared fields survive. This is the actual
            # "response_model" behaviour, not just validation, extra
            # fields your handler happened to include (e.g. an internal
            # 'password_hash' column pulled straight from a DB row) are
            # dropped rather than leaking to the client.
            return { map { $_ => $result->{$_} } keys %$schema };
        }

        die "with_response_model: \$schema must be a Type::Tiny object or a HashRef of field => Type::Tiny\n";
    };
}

=encoding utf-8

=head1 NAME

PAGI::FastAPI::ResponseModel - Response Shape Validation and Filtering for PAGI::FastAPI

=head1 VERSION

Version v1.2.4

=head1 SYNOPSIS

    use PAGI::FastAPI::ResponseModel qw(with_response_model);
    use Types::Standard qw(Str Int);

    # HashRef form: validates AND filters to just these fields.
    $app->get('/users/{id}',
        handler => with_response_model(
            { id => Int, name => Str, email => Str },   # note: no 'password_hash' here
            async sub ($c) {
                my $row = My::DB->find_user($c->path_param('id'));
                return $row;   # even if $row also has password_hash, last_login, etc.,
                               # only id/name/email reach the client
            }
        ),
    );

    # Type::Tiny object form: validates the whole return value as-is.
    use Types::Standard qw(ArrayRef);
    $app->get('/tags',
        handler => with_response_model(
            ArrayRef[Str],
            async sub ($c) { return My::DB->all_tags }
        ),
    );

=head1 DESCRIPTION

Python FastAPI's C<response_model> does two things: validates that a
handler's return value matches a declared shape, and filters the output to
only the declared fields (so accidentally returning an ORM row with extra
internal columns doesn't leak them). This module reproduces both, using the
exact same L<Type::Tiny>-based schema conventions
L<PAGI::FastAPI>'s own C<body> validation already uses, so it should feel
native rather than bolted-on.

B<Failure semantics:> if a handler's actual return value doesn't match its
declared C<response_model>, that's treated as a server bug (HTTP 500), not
a client error, mirroring Python FastAPI's C<ResponseValidationError>
behavior. The specific validation failure is logged via C<warn()>
server-side but not exposed in the response body, to avoid leaking internal
shape details to the client.

Response objects (anything C<isa(PAGI::FastAPI::Response)> or implementing
C<dispatch> the way SSE does) pass through untouched, a data schema doesn't
apply to an already-fully-formed response.

=head1 FUNCTIONS

=head2 C<with_response_model($schema, $handler)>

Returns a new coderef suitable for a route's C<handler> option.

C<$schema> is either:

=over 4

=item * A L<Type::Tiny> object/constraint, validates the entire returned
value against it. No filtering happens in this form since there's no set
of "declared fields" to filter to.

=item * A HashRef of C<< field => Type::Tiny >>, requires the handler to
return a HashRef, validates each declared field, and returns a I<new>
HashRef containing only the declared fields. Undeclared keys in the
handler's actual return value are silently dropped.

=back

=head1 CAVEATS

Filtering is shallow, nested HashRefs/ArrayRefs inside a field's value are
passed through as-is, not recursively filtered. For a field holding a
nested structure, validate/filter it explicitly inside your own handler, or
pass a L<Type::Tiny> constraint (e.g. from L<Types::Standard>'s C<Dict>)
that itself models the nested shape.

=head1 SEE ALSO

L<Type::Tiny>, L<Types::Standard>

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

    perldoc PAGI::FastAPI::ResponseModel

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

1; # End of PAGI::FastAPI::ResponseModel
