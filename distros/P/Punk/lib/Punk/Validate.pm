package Punk::Validate;

use 5.010;
use strict;
use warnings;
use Punk ();

our $VERSION = '0.28';

1;

__END__

=head1 NAME

Punk::Validate - collecting request validation

=head1 SYNOPSIS

    # imperative, in any handler
    post '/books' => sub {
        my ($c) = @_;
        my $v = $c->validate({
            type       => 'object',
            required   => ['title'],
            properties => {
                title => { type => 'string',  minLength => 1 },
                year  => { type => 'integer', minimum   => 1900 },
            },
        });
        if ($v->has_errors) {
            $c->flash(errors => { map { $_->{name} => $_->{message} }
                                  @{ $v->errors } });
            return $c->redirect('/books/new');
        }
        my $params = $v->valid;    # typed: year is an integer
        ...
    };

    # or declared on the route
    get '/books' => 'Web::Book#list', {
        validate => {
            type       => 'object',
            properties => { page => { type => 'integer', minimum => 1 } },
        },
    };

    post '/books' => 'Web::Book#create', {
        validate => { schema     => \%schema,
                      source     => 'params',
                      on_invalid => 'Web::Book#form' },
    };

    # MyApp::Controller::Web::Book - create only runs on valid input,
    # and a bare validate reads the Result the route guard stashed
    sub create {
        my ($c) = @_;
        my $params = $c->validate->valid;      # typed: year is an integer
        my $book   = $c->model('book')->create($params);
        return $c->redirect("/books/$book->{id}");
    }

    # ...and form is the on_invalid target: re-render with the errors
    sub form {
        my ($c) = @_;
        my $v = $c->validate;
        return $c->render('book/form', {
            errors => { map { $_->{name} => $_->{message} } @{ $v->errors } },
            values => $v->valid,
        }, status => 400);
    }

=head1 DESCRIPTION

Validation that B<collects>: invalid input never dies, it produces a
L</THE RESULT> the handler (or the generated route guard) turns into a
400 or a form re-render. This is the deliberate opposite of
L<Punk::Model>'s C<field> checks, which croak at write time because a
handler reaching the model with bad data is a bug; here the bad data is
the expected case. Only a malformed schema croaks - a boot-shaped error.

The whole tier is C (C<punk_validate.h>), running on the
L<JSON::Schema::Fast> C ABI: schemas are JSON Schema, compiled once
through the table with coercion on (a form's C<"1984"> satisfies
C<integer>) - a plain hashref is compiled and cached by its canonical
JSON, and a prebuilt C<JSON::Schema::Fast::Compiled> passes straight
through. The route guard is a C closure appended to the compiled route
record at boot; per request nothing is Perl but the calls that fetch
the data. Errors are in exactly L<Open::API>'s shape - the
JSON::Schema::Fast fields (C<instanceLocation>, C<keyword>,
C<schemaLocation>, C<message>) plus C<name> - so an API answers one
shape whether the route was validated by the OpenAPI mount or by
C<validate>.

=head1 THE CONTEXT METHOD

=head2 validate($schema, $data?)

Run a validation now. C<$data> defaults per request: the decoded JSON
body when the request's content type is JSON, the merged
C<< $c->params >> (captures, query, form) otherwise. Returns the
Result, which is also stashed for the no-argument form below.

=head2 validate

With no arguments, the reader: the last Result this request produced -
a route-level C<validate> ran before the handler, so this is how the
handler collects its outcome. Undef when nothing validated.

=head1 THE ROUTE OPTION

    get '/books' => $target, { validate => \%schema };
    post '/books' => $target, {
        validate => { schema => \%schema, source => 'params',
                      on_invalid => 'Web::Book#form' },
    };

The bare form is just a schema. The hashref-with-C<schema> form adds
C<source> (C<params> or C<json>; default auto per request) and
C<on_invalid> (a coderef or C<'Controller#method'> resolved at boot)
called with the context when validation fails - it sees the Result via
a bare C<< $c->validate >>, typically flashes the errors and redirects,
or re-renders the form. Without C<on_invalid> the failure answer is
C<< 400 { errors => [...] } >>, byte-shaped like the OpenAPI mount's.

The schema compiles once, at C<to_app>; a malformed one croaks naming
the route. The generated check runs B<after> the route's scope guards,
so an C<under> auth guard that answers 401 still costs no body parse.
On success the handler runs with the Result already stashed; C<valid>
hands it the typed params.

=head1 THE RESULT

A C<Punk::Validate::Result>, built and read in C.

=head2 has_errors

=head2 errors

The error count, and the arrayref of error hashrefs described above.

=head2 error($name)

The first message for one field - what a form template wants beside an
input. A root-level C<required> failure is expanded to one error per
missing property, so the message lands beside the right field.

=head2 valid / valid($name)

The typed, filtered parameters: only declared properties, numeric
strings numified for C<integer>/C<number>, booleans canonical C<1>/C<0>
- the shapes C<< $c->openapi >> delivers on an API mount. With a
precompiled schema there are no properties to filter by and the data
comes back as-is.

=head2 TO_JSON

C<< { errors => [...] } >> - the Result JSON-encodes as the 400 body.

=head1 SEE ALSO

L<Punk>, L<JSON::Schema::Fast>, L<Open::API>, L<Punk::Model>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
