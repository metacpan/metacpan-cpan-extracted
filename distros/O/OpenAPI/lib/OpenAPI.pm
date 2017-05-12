package OpenAPI;

use strict;
use warnings;

our $VERSION = '0.001';

1;

=head1 NAME

OpenAPI - A high-level implementation of the OpenAPI specification

=head1 DESCRIPTION

This module's functionality is entirely I<in potentiam>, which means I've not
written it yet.

The immediate purpose of it is to make sure there's something sensible in the
top-level namespace on the CPAN itself.

=head1 PLAN

=over

=item Create a set of classes that represent the types that the specification
lays out.

=item Create a validator that will validate an OpenAPI schema against the
OpenAPI specification.

=item Create a validator that will validate a Perl data structure against a
(valid) schema.

=item Create a system to produce a schema or set of schemata in a manner
agnostic to the URI schema, or lack thereof, on which the schema is served.

=item Somehow understand the URIs in the document, especially with regards to
the templated paths, such that the URI schema can be introspected, allowing for
integration with the various frameworks.

=item Understand hyperlinks within a third-party schema and denormalise, or
lazily fetch referenced schemata as required.

=item Conversely, have hyperlinks within a local schema that don't actually
have URIs associated with them yet.

=back

The idea is to be able to either parse or produce OpenAPI schemata and then
validate documents against it. When the OpenAPI schema is parsed it should look
the same as if it had been created locally, modulo lazy fetching of references.
That means that when a parsed schema is rendered out to JSON, it should look
the same as the original document.

Probably the sane way to do this would be to have the API object be a level
above the schemata themselves, as a sort of collection object, holding
sufficient information to reconstruct URIs absolutely, or resolve them
relatively.
