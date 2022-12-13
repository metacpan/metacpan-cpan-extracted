use strict;
use warnings;
package Mojolicious::Plugin::OpenAPI::Modern; # git description: v0.003-2-g9a4bd66
# vim: set ts=8 sts=2 sw=2 tw=100 et :
# ABSTRACT: Mojolicious plugin providing access to an OpenAPI document and parser
# KEYWORDS: validation evaluation JSON Schema OpenAPI Swagger HTTP request response

our $VERSION = '0.004';

use 5.020;
use if "$]" >= 5.022, experimental => 're_strict';
no if "$]" >= 5.031009, feature => 'indirect';
no if "$]" >= 5.033001, feature => 'multidimensional';
no if "$]" >= 5.033006, feature => 'bareword_filehandles';
use Mojo::Base 'Mojolicious::Plugin', -signatures;
use Feature::Compat::Try;
use YAML::PP;
use Path::Tiny;
use Mojo::JSON 'decode_json';
use Safe::Isa;
use OpenAPI::Modern 0.037;
use namespace::clean;

# we store data in two places: on the app (persistent storage, for the OpenAPI::Modern object
# itself) and in the controller stash: per-request data like the path info and extracted path items.

# the first is $app->openapi or $c->openapi
# the second is $c->stash('openapi') which will be initialized to {} on first use.
sub register ($self, $app, $config) {
  my $stash = Mojo::Util::_stash(openapi => $app);

  try {
    my $schema;
    if (exists $config->{schema}) {
      $schema = $config->{schema};
    }
    elsif (exists $config->{document_filename}) {
      if ($config->{document_filename} =~ /\.ya?ml$/) {
        $schema = YAML::PP->new(boolean => 'JSON::PP')->load_file($config->{document_filename}),
      }
      elsif ($config->{document_filename} =~ /\.json$/) {
        $schema = decode_json(path($config->{document_filename})->slurp_raw);
      }
      else {
        die 'Unsupported file format in filename: ', $config->{document_filename};
      }
    }
    else {
      die 'missing config: one of schema, filename';
    }

    my $openapi = OpenAPI::Modern->new(
      openapi_uri    => $config->{document_filename} // '',
      openapi_schema => $schema,
    );

    # leave room for other keys in our localized stash
    $stash->{openapi} = $openapi;
  }
  catch ($e) {
    die 'Cannot load OpenAPI document: ', $e;
  }

  $app->helper(openapi => sub ($c) { $stash->{openapi} });

  $app->helper(validate_request => \&_validate_request);
  $app->helper(validate_response => \&_validate_response);
}

sub _validate_request ($c) {
  my $options = $c->stash->{openapi} //= {};
  return $c->openapi->validate_request($c->req, $options);
}

sub _validate_response ($c) {
  my $options = $c->stash->{openapi} //= {};
  local $options->{request} = $c->req;
  return $c->openapi->validate_response($c->res, $options);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::OpenAPI::Modern - Mojolicious plugin providing access to an OpenAPI document and parser

=head1 VERSION

version 0.004

=head1 SYNOPSIS

  $app->config({
    openapi => {
      document_filename => 'data/openapi.yaml',
    },
    ...
  });

  $app->plugin('OpenAPI::Modern', $app->config->{openapi});

  # in a controller...
  my $result = $c->openapi->validate_request($c->req);

=head1 DESCRIPTION

This L<Mojolicious> plugin makes an L<OpenAPI::Modern> object available to the application.

There are many features to come.

=head1 CONFIGURATION OPTIONS

=head2 schema

The literal, unblessed Perl data structure containing the OpenAPI document. See
L<OpenAPI::Modern/openapi_schema>.

=head2 document_filename

A filename indicating from where to load the OpenAPI document. Supports YAML and json file formats.

=head1 METHODS

=head2 register

Instantiates an L<OpenAPI::Modern> object and provides an accessor to it.

=head1 HELPERS

These methods are made available on the C<$c> object (the invocant of all controller methods,
and therefore other helpers).

=for stopwords openapi operationId

=head2 openapi

The L<OpenAPI::Modern> object.

=head2 validate_request

  my $result = $c->openapi->validate_request;

Passes C<< $c->req >> to L<OpenAPI::Modern/validate_request> and returns the
L<JSON::Schema::Modern::Result>.

Note that the matching L<Mojo::Routes::Route> object for this request is I<not> used to find the
OpenAPI path-item that corresponds to this request: only information in the request URI itself is
used (although some information in the route may be used in a future feature).

=head2 validate_response

  my $result = $c->openapi->validate_response;

Passes C<< $c->res >> and C<< $c->req >> to L<OpenAPI::Modern/validate_response> and returns the
L<JSON::Schema::Modern::Result>.

Can only be called in the areas of the dispatch flow where the response has already been rendered; a
good place to call this would be in an L<after_dispatch|Mojolicious/after_dispatch> hook.

Note that the matching L<Mojo::Routes::Route> object for this request is I<not> used to find the
OpenAPI path-item that corresponds to this request and response: only information in the request URI
itself is used (although some information in the route may be used in a future feature).

=head1 STASH VALUES

This plugin stores all its data under the C<openapi> hashref, e.g.:

  my $operation_id = $c->stash->{openapi}{operation_id};

Keys starting with underscore are for I<internal use only> and should not be relied upon to behave
consistently across release versions. Values that may be used by controllers and templates are:

=over 4

=item *

C<path_template>: Set by the first call to L</validate_request> or L</validate_response>. A string representing the request URI, with placeholders in braces (e.g. C</pets/{petId}>); see L<https://spec.openapis.org/oas/v3.1.0#paths-object>.

=item *

C<path_captures>: Set by the first call to L</validate_request> or L</validate_response>. A hashref mapping placeholders in the path to their actual values in the request URI.

=item *

C<operation_id>: Set by the first call to L</validate_request> or L</validate_response>. Contains the corresponding L<operationId|https://swagger.io/docs/specification/paths-and-operations/#operationid> of the current endpoint.

=item *

C<method>: Set by the first call to L</validate_request> or L</validate_response>. The HTTP method used by the request, lower-cased.

=back

=head1 SEE ALSO

=over 4

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

Bugs may be submitted through L<https://github.com/karenetheridge/Mojolicious-Plugin-OpenAPI-Modern/issues>.

I am also usually active on irc, as 'ether' at C<irc.perl.org> and C<irc.libera.chat>.

You can also find me on the L<JSON Schema Slack server|https://json-schema.slack.com> and L<OpenAPI Slack
server|https://open-api.slack.com>, which are also great resources for finding help.

=head1 AUTHOR

Karen Etheridge <ether@cpan.org>

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2021 by Karen Etheridge.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
