use strict;
use warnings;
package JSON::Schema::Modern::Vocabulary::OpenAPI;
# vim: set ts=8 sts=2 sw=2 tw=100 et :
# ABSTRACT: Implementation of the JSON Schema OpenAPI vocabulary

our $VERSION = '0.041';

use 5.020;
use Moo;
use strictures 2;
use experimental qw(signatures postderef);
use if "$]" >= 5.022, experimental => 're_strict';
no if "$]" >= 5.031009, feature => 'indirect';
no if "$]" >= 5.033001, feature => 'multidimensional';
no if "$]" >= 5.033006, feature => 'bareword_filehandles';
use JSON::Schema::Modern::Utilities 0.524 qw(assert_keyword_type annotate_self E is_type jsonp);
use namespace::clean;

with 'JSON::Schema::Modern::Vocabulary';

sub vocabulary {
  'https://spec.openapis.org/oas/3.1/vocab/base' => 'draft2020-12',
}

sub keywords {
  qw(discriminator example externalDocs xml);
}

sub _traverse_keyword_discriminator ($self, $schema, $state) {
  return if not assert_keyword_type($state, $schema, 'object');

  # "the discriminator field MUST be a required field"
  return E($state, 'missing required field propertyName')
    if not exists $schema->{discriminator}{propertyName};
  return E({ %$state, _schema_path_suffix => 'propertyName' }, 'discriminator propertyName is not a string')
    if not is_type('string', $schema->{discriminator}{propertyName});

  my $valid = 1;
  if (exists $schema->{discriminator}{mapping}) {
    return if not assert_keyword_type({ %$state, _schema_path_suffix => 'mapping' }, $schema, 'object');
    return E({ %$state, _schema_path_suffix => 'mapping' }, 'discriminator mapping is not an object ')
      if not is_type('object', $schema->{discriminator}{mapping});
    foreach my $mapping_key (sort keys $schema->{discriminator}{mapping}->%*) {
      my $uri = $schema->{discriminator}{mapping}{$mapping_key};
      $valid = E({ %$state, _schema_path_suffix => [ 'mapping', $mapping_key ] }, 'discriminator mapping value for "%s" is not a string', $mapping_key), next if not is_type('string', $uri);
    }
  }

  $valid = E($state, 'missing sibling keyword: one of oneOf, anyOf, allOf')
    if not grep exists $schema->{$_}, qw(oneOf anyOf allOf);

  return 1;
}

sub _eval_keyword_discriminator ($self, $data, $schema, $state) {
  # Note: the spec is unclear of the expected behaviour when the data instance is not an object
  return 1 if not is_type('object', $data);

  my $discriminator_key = $schema->{discriminator}{propertyName};

  # property with name <propertyName> MUST be present in the data payload
  return E($state, 'missing required discriminator field "%s"', $discriminator_key)
    if not exists $data->{$discriminator_key};

  my $discriminator_value = $data->{$discriminator_key};

  # if /components/$discriminator_value exists, that schema must validate
  my $uri = Mojo::URL->new->fragment(jsonp('', qw(components schemas), $discriminator_value))
    ->to_abs($state->{initial_schema_uri});
  if (my $component_schema_info = $state->{evaluator}->_fetch_from_uri($uri)) {
    $state = { %$state, _schema_path_suffix => 'propertyName' };
  }
  elsif (exists $schema->{discriminator}{mapping} and exists $schema->{discriminator}{mapping}{$discriminator_value}) {
    # use 'mapping' to determine which schema to use.
    $uri = Mojo::URL->new($schema->{discriminator}{mapping}{$discriminator_value});
    $state = { %$state, _schema_path_suffix => [ 'mapping', $discriminator_value ] };
  }
  else {
    # If the discriminator value does not match an implicit or explicit mapping, no schema can be
    # determined and validation SHOULD fail.
    return E($state, 'invalid %s: "%s"', $discriminator_key, $discriminator_value);
  }

  return E($state, 'subschema for %s: %s is invalid', $discriminator_key, $discriminator_value)
    if not $self->eval_subschema_at_uri($data, $schema, $state, $uri);
  return 1;
}

sub _traverse_keyword_example { 1 }

sub _eval_keyword_example ($self, $data, $schema, $state) {
  annotate_self($state, $schema);
}

# until we do something with these values, we do not bother checking the structure
sub _traverse_keyword_externalDocs { 1 }

sub _eval_keyword_externalDocs { goto \&_eval_keyword_example }

# until we do something with these values, we do not bother checking the structure
sub _traverse_keyword_xml { 1 }

sub _eval_keyword_xml { goto \&_eval_keyword_example }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JSON::Schema::Modern::Vocabulary::OpenAPI - Implementation of the JSON Schema OpenAPI vocabulary

=head1 VERSION

version 0.041

=head1 DESCRIPTION

=for Pod::Coverage vocabulary keywords

=for stopwords metaschema

Implementation of the JSON Schema "OpenAPI" vocabulary, indicated in metaschemas
with the URI C<https://spec.openapis.org/oas/3.1/vocab/base> and formally specified in
L<https://spec.openapis.org/oas/v3.1.0#schema-object>.

This vocabulary is normally made available by using the metaschema
L<https://spec.openapis.org/oas/3.1/dialect/base>.

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

L<https://www.openapis.org/>

=item *

L<https://oai.github.io/Documentation/>

=item *

L<https://spec.openapis.org/oas/v3.1.0>

=back

=head1 SUPPORT

Bugs may be submitted through L<https://github.com/karenetheridge/OpenAPI-Modern/issues>.

I am also usually active on irc, as 'ether' at C<irc.perl.org> and C<irc.libera.chat>.

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
