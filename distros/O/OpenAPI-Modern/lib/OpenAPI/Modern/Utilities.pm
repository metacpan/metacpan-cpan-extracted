use strictures 2;
package OpenAPI::Modern::Utilities;
# vim: set ts=8 sts=2 sw=2 tw=100 et :
# ABSTRACT: Internal utilities and common definitions for OpenAPI::Modern

our $VERSION = '0.113';

use 5.020;
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
use File::ShareDir 'dist_dir';
use Mojo::File 'path';
use JSON::Schema::Modern::Utilities 0.625 qw(register_schema load_cached_document);
use namespace::clean;

use Exporter 'import';

our @EXPORT = qw(
  SUPPORTED_OAD_VERSIONS
  OAS_VERSIONS
  DEFAULT_DIALECT
  DEFAULT_BASE_METASCHEMA
  DEFAULT_METASCHEMA
  STRICT_METASCHEMA
  STRICT_DIALECT
  OAS_VOCABULARY
);

our @EXPORT_OK = qw(
  OAS_SCHEMAS
  add_vocab_and_default_schemas
);

our %EXPORT_TAGS = (
  constants => \@EXPORT,
);

# it is likely the case that we can support a version beyond what's stated here -- but we may not,
# so we'll warn to that effect. Every effort will be made to upgrade this implementation to fully
# support the latest point release as soon as possible.
use constant SUPPORTED_OAD_VERSIONS => [ '3.0.4', '3.1.2', '3.2.0' ];

# in most things, e.g. schemas, we only use major.minor as the version number
# we don't actually support OAS 3.0.x, but we will bundle its schema so it can be more easily used
# for validating v3.0 OADs
use constant OAS_VERSIONS => [ map s/^\d+\.\d+\K\.\d+$//r, SUPPORTED_OAD_VERSIONS->@* ];

# see https://spec.openapis.org/#openapi-specification-schemas for the latest links
# these are updated automatically at build time via 'update-schemas'

# the main OpenAPI document schema, with permissive (unvalidated) JSON Schemas
use constant DEFAULT_METASCHEMA => {
  '3.0' => 'https://spec.openapis.org/oas/3.0/schema/2024-10-18',
  '3.1' => 'https://spec.openapis.org/oas/3.1/schema/2025-09-15',
  '3.2' => 'https://spec.openapis.org/oas/3.2/schema/2025-09-17',
};

# metaschema for JSON Schemas contained within OpenAPI documents:
# standard JSON Schema (presently draft2020-12) + OpenAPI vocabulary
use constant DEFAULT_DIALECT => {
  '3.0' => DEFAULT_METASCHEMA->{'3.0'}.'#/definitions/Schema',
  '3.1' => 'https://spec.openapis.org/oas/3.1/dialect/2024-11-10',
  '3.2' => 'https://spec.openapis.org/oas/3.2/dialect/2025-09-17',
};

# OpenAPI document schema that forces the use of the JSON Schema dialect (no $schema overrides
# permitted)
use constant DEFAULT_BASE_METASCHEMA => {
  '3.0' => 'https://spec.openapis.org/oas/3.0/schema/2024-10-18', # same as standard
  '3.1' => 'https://spec.openapis.org/oas/3.1/schema-base/2025-09-15',
  '3.2' => 'https://spec.openapis.org/oas/3.2/schema-base/2025-09-17',
};

# OpenAPI vocabulary definition
use constant OAS_VOCABULARY => {
  '3.1' => 'https://spec.openapis.org/oas/3.1/meta/2024-11-10',
  '3.2' => 'https://spec.openapis.org/oas/3.2/meta/2025-09-17',
};

# an OpenAPI schema and JSON Schema dialect which prohibit unknown keywords
use constant STRICT_METASCHEMA => {
  '3.1' => 'https://raw.githubusercontent.com/karenetheridge/OpenAPI-Modern/master/share/3.1/strict-schema.json',
  '3.2' => 'https://raw.githubusercontent.com/karenetheridge/OpenAPI-Modern/master/share/3.2/strict-schema.json',
};

use constant STRICT_DIALECT => {
  '3.1' => 'https://raw.githubusercontent.com/karenetheridge/OpenAPI-Modern/master/share/3.1/strict-dialect.json',
  '3.2' => 'https://raw.githubusercontent.com/karenetheridge/OpenAPI-Modern/master/share/3.2/strict-dialect.json',
};

# <uri> => <local filename> (under share/) - for internal use only!
use constant _BUNDLED_SCHEMAS => {
  map +(
    DEFAULT_METASCHEMA->{$_}        => 'oas/'.$_.'/schema.json',
    $_ eq '3.0' ? () : (
      DEFAULT_DIALECT->{$_}         => 'oas/'.$_.'/dialect.json',
      DEFAULT_BASE_METASCHEMA->{$_} => 'oas/'.$_.'/schema-base.json',
      OAS_VOCABULARY->{$_}          => 'oas/'.$_.'/vocabulary.json',
      STRICT_METASCHEMA->{$_}       => $_.'/strict-schema.json',
      STRICT_DIALECT->{$_}          => $_.'/strict-dialect.json',
    )
  ), OAS_VERSIONS->@*
};

# these are all loadable on demand, via JSON::Schema::Modern::load_cached_document,
# and also made available as s/<date>/latest/
# { <oas version> => [ <uri>, <uri>, .. ]
use constant OAS_SCHEMAS => {
  map {
    my $version = $_;
    $version => [ grep m{/oas/$version/}, keys _BUNDLED_SCHEMAS->%* ]
  } OAS_VERSIONS->@*
};


sub add_vocab_and_default_schemas ($evaluator, $version = OAS_VERSIONS->[-1]) {
  $evaluator->add_vocabulary('JSON::Schema::Modern::Vocabulary::OpenAPI');

  $evaluator->add_format_validation(int32 => +{
    type => 'number',
    sub => sub ($x) {
      require Math::BigInt; Math::BigInt->VERSION(1.999701);
      $x = Math::BigInt->new($x);
      return if $x->is_nan;
      my $bound = Math::BigInt->new(2) ** 31;
      $x >= -$bound && $x < $bound;
    }
  });

  $evaluator->add_format_validation(int64 => +{
    type => 'number',
    sub => sub ($x) {
      require Math::BigInt; Math::BigInt->VERSION(1.999701);
      $x = Math::BigInt->new($x);
      return if $x->is_nan;
      my $bound = Math::BigInt->new(2) ** 63;
      $x >= -$bound && $x < $bound;
    }
  });

  $evaluator->add_format_validation(float => +{ type => 'number', sub => sub ($x) { 1 } });
  $evaluator->add_format_validation(double => +{ type => 'number', sub => sub ($x) { 1 } });
  $evaluator->add_format_validation(password => +{ type => 'string', sub => sub ($) { 1 } });

  foreach my $uri (OAS_SCHEMAS->{$version}->@*) {
    my $document = load_cached_document($evaluator, $uri);

    # add "latest" alias for each of these documents, mapping to the same document object
    $evaluator->add_document(($document->canonical_uri =~ s{/\d{4}-\d{2}-\d{2}$}{}r).'/latest', $document);
  }
}

{
  # make all bundled schemas available via JSON::Schema::Modern::load_cached_document
  my $share_dir = dist_dir('OpenAPI-Modern');
  foreach my $uri (keys _BUNDLED_SCHEMAS->%*) {
    register_schema($uri, $share_dir.'/'._BUNDLED_SCHEMAS->{$uri});
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpenAPI::Modern::Utilities - Internal utilities and common definitions for OpenAPI::Modern

=head1 VERSION

version 0.113

=head1 SYNOPSIS

  use OpenAPI::Modern::Utilities;

=head1 DESCRIPTION

This class contains common definitions and internal utilities to be used by L<OpenAPI::Modern>.

=for Pod::Coverage DEFAULT_BASE_METASCHEMA
DEFAULT_DIALECT
DEFAULT_METASCHEMA
OAS_SCHEMAS
OAS_VERSIONS
OAS_VOCABULARY
STRICT_DIALECT
STRICT_METASCHEMA
SUPPORTED_OAD_VERSIONS
add_vocab_and_default_schemas

The constant values are updated automatically by C<update-schemas>, in the root of this distribution.

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
