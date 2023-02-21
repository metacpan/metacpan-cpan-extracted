# no code
## no critic: TestingAndDebugging::RequireUseStrict
package Sah::Schemas::JSON;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-11-15'; # DATE
our $DIST = 'Sah-Schemas-JSON'; # DIST
our $VERSION = '0.007'; # VERSION

1;
# ABSTRACT: Various schemas related to JSON

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schemas::JSON - Various schemas related to JSON

=head1 VERSION

This document describes version 0.007 of Sah::Schemas::JSON (from Perl distribution Sah-Schemas-JSON), released on 2022-11-15.

=head1 SAH SCHEMAS

The following schemas are included in this distribution:

=over

=item * L<any_from_json|Sah::Schema::any_from_json>

A data structure, coerced from JSON string.

You can use this schema if you want to accept any data (a data structure or
simple scalar), but if user supplies a defined string e.g. in a command-line
script as command-line argument or option, the string will be assumed to be a
JSON-encoded value and decoded. Data will not be valid if the string does not
contain valid JSON.

Thus, if you want to supply a string, you have to JSON-encode it.


=item * L<array_from_json|Sah::Schema::array_from_json>

Array, coercible from JSON string.

You can use this schema if you want to accept an array, but if user supplies a
string e.g. in a command-line script as command-line argument or option, the
string will be coerced into array if the string contains a JSON-encoded array.
Data will not be valid if the string does not contain valid JSON.

Note that array data is accepted, unlike the C<json_str::array> schema which only
accepts JSON-encoded array in string form.


=item * L<hash_from_json|Sah::Schema::hash_from_json>

Hash, coerced from JSON string.

You can use this schema if you want to accept a hash, but if user supplies a
string e.g. in a command-line script as command-line argument or option, the
string will be coerced into hash if the string contains a JSON-encoded object
(hash). Data will not be valid if the string does not contain valid JSON.

Note that hash data is accepted, unlike the C<json_str::hash> schema which only
accepts hash in JSON-encoded string form.


=item * L<json_or_str|Sah::Schema::json_or_str>

A JSON-encoded data or string.

You can use this schema if you want to accept any data (a data structure or
simple scalar), and if user supplies a defined string e.g. in a command-line
script as command-line argument or option, it will be tried to be JSON-decoded
first. If the string does not contain valid JSON, it will be left as-is as
string.

This schema is convenient on the command-line where you want to accept data
structure via command-line argument or option. But you have to be careful when
you want to pass a string like C<null>, C<true>, C<false>; you have to quote it to
C<"null">, C<"true">, C<"false"> to prevent it being decoded into undef or
boolean values.

See also related schema: C<json_str>, C<str::encoded_json>, C<str::escaped_json>.


=item * L<json_str|Sah::Schema::json_str>

A string that contains valid JSON.

This schema can be used if you want to accept a string that contains valid JSON.
The JSON string will not be decoded (e.g. a JSON-encoded array will not beome an
array) but you know that the string contains a valid JSON. Data will not be
valid if the string does not contain valid JSON.

See also related schema: C<json_or_str>, C<str::encoded_json>,
C<str::escaped_json>.


=item * L<json_str::array|Sah::Schema::json_str::array>

A string that contains valid JSON and the JSON encodes an array.

This schema is like the C<json_str> schema: it accepts a string that contains
valid JSON. The JSON string will not be decoded but you know that the string
contains a valid JSON. In addition to that, the JSON must encode an array. Data
will not be valid if it is not a valid JSON or if the JSON is not an array.

Note that unlike the C<array_from_json> schema, an array data is not accepted by
this schema. Data must be a string.


=item * L<json_str::hash|Sah::Schema::json_str::hash>

A string that contains valid JSON and the JSON encodes a hash (JavaScript object).

This schema is like the C<json_str> schema: it accepts a string that contains
valid JSON. The JSON string will not be decoded but you know that the string
contains a valid JSON. In addition to that, the JSON must encode a hash
(JavaScript object). Data will not be valid if it is not a valid JSON or if the
JSON is not a hash.

Note that unlike the C<hash_from_json> schema, a hash data is not accepted by
this schema. Data must be a string.


=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-JSON>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-JSON>.

=head1 SEE ALSO

L<Sah::Schemas::Str>

L<Sah> - schema specification

L<Data::Sah> - Perl implementation of Sah

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022, 2021 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-JSON>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
