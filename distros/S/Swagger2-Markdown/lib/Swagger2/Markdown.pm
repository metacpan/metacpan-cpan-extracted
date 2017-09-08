package Swagger2::Markdown;

=head1 NAME

Swagger2::Markdown - DEPRECATED convert a Swagger2 spec to various markdown formats

=for html
<a href='https://travis-ci.org/Humanstate/swagger2-markdown?branch=master'><img src='https://travis-ci.org/Humanstate/swagger2-markdown.svg?branch=master' alt='Build Status' /></a>
<a href='https://coveralls.io/r/Humanstate/swagger2-markdown?branch=master'><img src='https://coveralls.io/repos/Humanstate/swagger2-markdown/badge.png?branch=master' alt='Coverage Status' /></a>

=head1 VERSION

9.99

=head1 DEPRECATION WARNING

The Swagger2 distribution is no longer actively maintained. Ergo, this distribution
is no longer actively maintained. If you would like to create an OpenAPI2::Markdown
then please feel free.

If you're looking at generating API docs from your Swagger2/OpenAPI spec then take
a look at L<https://github.com/Rebilly/ReDoc>

=head1 SYNOPSIS

    use strict;
    use warnings;

    use Swagger2;
    use Swagger2::Markdown;

    my $s2md = Swagger2::Markdown->new(
        swagger2 => Swagger2->new->load( $path_to_swagger_spec )
    );

    my $api_bp_str   = $s2md->api_blueprint;

    my $markdown_str = $s2md->markdown( %pod_markdown_opts );

=head1 DESCRIPTION

This module allows you to convert a swagger specification file to API Blueprint
markdown and basic markdown. Note that you may need to add C<x-> values to your
swagger config file to get better markdown output.

=cut

use strict;
use warnings;

use Moo;
use Types::Standard qw/ :all /;
use Template;
use Swagger2::Markdown::API::Blueprint;
use Pod::Markdown;

our $VERSION = '9.99';

=head1 ATTRIBUTES

=head2 swagger2

The L<Swagger2> object, required at instantiation

=cut

has 'swagger2' => (
    is       => 'ro',
    isa      => InstanceOf['Swagger2'],
    required => 1,
);

has '_template' => (
    is       => 'ro',
    isa      => InstanceOf['Template'],
    default  => sub {
        return Template->new({

        });
    },
);

=head1 METHODS

=cut

=head2 markdown

Returns a string of markdown using the L<Pod::Markdown> parser - the pod string is
retrieved from the ->pod method of L<Swagger2>. As the parser is L<Pod::Markdown>
you can pass in a hash of arguments that will be passed on to the L<Pod::Markdown>
instantiation call:

    my $markdown = $s2md->markdown( %pod_markdown_opts );

=cut

sub markdown {
    my ( $self,%options ) = @_;

    my $parser = Pod::Markdown->new(
        match_encoding => 1,
        %options
    );

    {
        # Pod::Markdown will escape any markdown reserved chars, but since we can
        # include markdown in the swagger config we *don't* want to do that. this
        # hack stops Pod::Markdown escaping the reserved chars, since there isn't
        # an option to prevent the module doing so
        no warnings 'redefine';
        *Pod::Markdown::_escape_inline_markdown = sub { return $_[1] };
        *Pod::Markdown::_escape_paragraph_markdown = sub { return $_[1] };
    }

    $parser->output_string( \my $markdown );
    $parser->parse_string_document(
        $self->swagger2->pod->to_string
    );

    return $markdown;
}

=head2 api_blueprint

Returns a string of markdown in API Blueprint format. Because API Blueprint is more
of a documentation orientated approach there are some sections that it contains that
are not present in the swagger2 spec. Refer to the API Blueprint specification for
the following terms: L<https://github.com/apiaryio/api-blueprint/blob/master/API%20Blueprint%20Specification.md>

You should add C<x-api-blueprint> sections to the swagger2 config to define which
format of API Blueprint output you want and to add extra summary and method
documentation. The main layout of the API Blueprint file is defined as so in the top
level of the swagger config file (YAML example here with defaults shown):

    x-api-blueprint:
      resource_section: method_uri
      action_section: method_uri
      attributes: false
      simple: false
      data_structures: false

Possible values for resource_section are:

    uri             - # <URI template>
    name_uri        - # <identifier> [<URI template>]
    method_uri      - # <HTTP request method> <URI template>
    name_method_uri - # <identifier> [<HTTP request method> <URI template>]

Possible values for action_section are:

    method          - ## <HTTP request method>
    name_method     - ## <identifier> [<HTTP request method>]
    name_method_uri - ## <identifier> [<HTTP request method> <URI template>]
    method_uri      - # <HTTP request method> <URI template>

Possible values for C<attributes> are true and false - if true the Attributes
sections will be created in the API Blueprint output.

Possible values for C<simple> are true and false - if true then only the resource
section headers will be printed.

Possible values for C<data_structures> are true and false - if true then only a
Data Structures section will be output to show definitions, and those request or
response parameters that reference those (using C<$ref>) will also reference the
Data Structures section.

For paths needing extra documentation you can add an C<x-api-blueprint> section to
the path like so (again, YAML example here):

    paths:
      /message:
        x-api-blueprint:
          group: Messages
          summary: My Message
          description: |
            The description that will appear under the group section
          group_description: |
            The description that will appear under the resource_section header

C<summary> and C<description> should be self explanatory, C<group> will make the API
Blueprint output use grouping resources format

You can add examples to the parameters section of a method using C<x-example>:

    paths:
      /messages:
        get:
          parameters:
            - in: query
              ...
              x-example: 3

=cut

sub api_blueprint {
    my ( $self,$args ) = @_;

    my $output;

    $self->_template->process(
        Swagger2::Markdown::API::Blueprint->template,
        {
            # api blueprint output config
            o => $self->swagger2->api_spec->data->{'x-api-blueprint'},
            # expanded
            e => $self->swagger2->expand->api_spec->data,
            # compacted
            c => $self->swagger2->api_spec->data,
            # definitions
            d => $self->swagger2->api_spec->data->{definitions},
        },
        \$output,
    ) || die $self->_template->error;

    return $output;
}

=head1 EXAMPLES

See the tests in this distribution - for example t/swagger/foo.yaml will map
to t/markdown/foo.md when called with ->markdown and t/api_blueprint/foo.md
when called with ->api_blueprint.

=head1 SEE ALSO

L<Swagger2>

L<Pod::Markdown>

=head1 BUGS

Certainly. This has only been tested against the example markdown files on
the API Blueprint github repo, and for that i had to generate the swagger
files by hand.

=head1 AUTHOR

Lee Johnson - C<leejo@cpan.org>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. If you would like to contribute documentation
please raise an issue / pull request:

    https://github.com/Humanstate/swagger2-markdown

=cut

__PACKAGE__->meta->make_immutable;

# vim: ts=4:sw=4:et

