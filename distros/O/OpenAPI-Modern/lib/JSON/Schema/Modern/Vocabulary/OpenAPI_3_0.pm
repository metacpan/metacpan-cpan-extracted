use strictures 2;
package JSON::Schema::Modern::Vocabulary::OpenAPI_3_0;
# vim: set ts=8 sts=2 sw=2 tw=100 et :
# ABSTRACT: Implementation of the JSON Schema OpenAPI 3.0 pseudo-vocabulary

our $VERSION = '0.119';

use 5.020;
use utf8;
use Moo;
use strictures 2;
use stable 0.031 'postderef';
use experimental 'signatures';
no autovivification warn => qw(fetch store exists delete);
use if "$]" >= 5.022, experimental => 're_strict';
no if "$]" >= 5.031009, feature => 'indirect';
no if "$]" >= 5.033001, feature => 'multidimensional';
no if "$]" >= 5.033006, feature => 'bareword_filehandles';
no if "$]" >= 5.041009, feature => 'smartmatch';
no feature 'switch';
use Scalar::Util 'looks_like_number';
use JSON::Schema::Modern::Utilities qw(get_type E);
use namespace::clean;

with 'JSON::Schema::Modern::Vocabulary';

sub vocabulary {}

my $vocabulary_mapping = {
  Core => [ '$ref' ],
  Validation => [ qw(
    type
    enum
    multipleOf
    maximum
    exclusiveMaximum
    minimum
    exclusiveMinimum
    maxLength
    minLength
    pattern
    maxItems
    minItems
    uniqueItems
    maxProperties
    minProperties
    required
  ) ],
  Applicator => [ qw(
    allOf
    anyOf
    oneOf
    not
    items
    properties
    additionalProperties
  ) ],
  Format => [ 'format' ],
  MetaData => [ qw(
    title
    description
    default
    deprecated
    readOnly
    writeOnly
    example
  ) ],
  # unique to OAS; all of these have null implementations
  Other => [ qw(
    nullable
    discriminator
    externalDocs
  ) ],
};

sub keywords {
  # most of these can be directly mapped to JSON Schema vocabulary keywords (3.0.4 §4.7.24.1).
  map @$_, $vocabulary_mapping->@{qw(Core Validation Applicator Format MetaData Other)};
}


# v3.0.4 §4.4: "Data types in the OAS are based on the non-null types supported by the JSON Schema
# Validation Specification Draft Wright-00: “boolean”, “object”, “array”, “number”, “string”, or
# “integer”. See nullable for an alternative solution to “null” as a type."
# v3.0.4 §4.7.24.1: ""items" MUST be present if type is "array"."
# "["type"] Value MUST be a string. Multiple types via an array are not supported."

sub _eval_keyword_type ($class, $data, $schema, $state) {
  return 1 if not defined $data and $schema->{nullable};

  my $type = get_type($data, { legacy_ints => 1 });
  my $want = $schema->{type};

  return 1 if
    $type eq $want or ($want eq 'number' and $type eq 'integer')
      or ($type eq 'string' and $state->{stringy_numbers} and looks_like_number($data)
          and ($want eq 'number' or ($want eq 'integer' and $data == int($data))))
      or ($want eq 'boolean' and $state->{scalarref_booleans} and $type eq 'reference to SCALAR');

  return E($state, 'got %s, not %s%s', $type, $want, $schema->{nullable} ? ' or null' : '');
}

foreach my $vocabulary (keys %$vocabulary_mapping) {
  foreach my $keyword ($vocabulary_mapping->{$vocabulary}->@*) {

    # There is no need to rigorously traverse schemas in v3.0 OpenAPI documents, as there are no
    # embedded identifiers to find ("id" is not a valid keyword).
    # The document validation pass on the document that we already do is sufficient to check the
    # schema keywords' syntax, and this saves us from having to implement custom methods for every
    # keyword that uses a subset of normal draft4 syntax (see v3.0.4 §4.7.24.1).

    my $k = $keyword =~ s/^\$//r;

    no strict 'refs';
    *{__PACKAGE__.'::_traverse_keyword_'.$k} = sub { 1 };

    next if $keyword eq 'type';

    # these keywords are no-ops
    next if $vocabulary eq 'MetaData' or $vocabulary eq 'Other';

    my $name = '_eval_keyword_'.$k;
    *{__PACKAGE__.'::'.$name} = *{'JSON::Schema::Modern::Vocabulary::'.$vocabulary.'::'.$name};
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JSON::Schema::Modern::Vocabulary::OpenAPI_3_0 - Implementation of the JSON Schema OpenAPI 3.0 pseudo-vocabulary

=head1 VERSION

version 0.119

=head1 DESCRIPTION

=for stopwords schema

Implementation of the
L<JSON Schema dialect used by OpenAPI 3.0.x documents|https://spec.openapis.org/oas/v3.0.4.html#schema-object>.
This is not a true vocabulary class as it cannot be referenced in C<$vocabulary> keywords in JSON
Schemas; instead it is a representation of the dialect as referenced by the C<Schema> definition in
the schema used for OpenAPI 3.0.x, implemented by mapping the definitions of all supported keywords
to their equivalents in the C<draft4> JSON Schema specification (with appropriate modifications as
noted by the specification, as not every keyword is implemented identically).

=head1 SEE ALSO

=over 4

=item *

L<Mojolicious::Plugin::OpenAPI::Modern>

=item *

L<OpenAPI::Modern>

=item *

L<JSON::Schema::Modern::Document::OpenAPI>

=item *

L<JSON::Schema::Modern>

=item *

L<https://json-schema.org>

=item *

L<https://www.openapis.org>

=item *

L<https://learn.openapis.org>

=item *

L<https://spec.openapis.org/oas/v3.0>

=back

=head1 GIVING THANKS

=for stopwords MetaCPAN GitHub

If you found this module to be useful, please show your appreciation by
adding a +1 in L<MetaCPAN|https://metacpan.org/dist/OpenAPI-Modern>
and a star in L<GitHub|https://github.com/karenetheridge/OpenAPI-Modern>.

=head1 SUPPORT

Bugs may be submitted through L<https://github.com/karenetheridge/OpenAPI-Modern/issues>.

I am also usually active on irc, as 'ether' at C<irc.perl.org> and C<irc.libera.chat>.

=for stopwords OpenAPI

You can also find me on the L<JSON Schema Slack server|https://json-schema.slack.com> and L<OpenAPI
Slack server|https://open-api.slack.com>, which are also great resources for finding help.

=head1 AUTHOR

Karen Etheridge <ether@cpan.org>

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2021 by Karen Etheridge.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Some schema files have their own licence, in share/oas/LICENSE.

=cut
