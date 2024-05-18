# NAME

Mojolicious::Plugin::Data::Transfigure - Mojolicious adapter for Data::Transfigure

# SYNOPSIS

    # in startup
    $app->plugin('Data::Transfigure' => {
      renderers => [qw(json openapi)]
    });

    $app->transfig->output->add_transfigurators(
      Data::Transfigure::Type->new(
        type => "App::Model::Result::Book",
        handler => sub($data) {
          +{
            id     => $data->id,
            name   => $data->name,
            author => $data->author,
          }
        }
      ),
      Data::Transfigure::Type->new(
        type => 'App::Model::Result::Person',
        handler => sub($data) {
          +{
            id        => $data->id,
            firstname => $data->names->[0],
            lastname  => $data->names->[1],
          }
        }
      )
    );

    $app->transfig->input->add_transfigurators(
      Data::Transfigure::Position->new(
        position => '/**/author',
        handler  => sub($data) {
          +{
            id    => $data->id,
            names => [$data->{firstname}, $data->{lastname}]
          }
        } 
      )
    );

    # in controller
    sub get_book($self) {
      my $book = $self->model("Book")->find($self->param('id'));
      $self->render(json => $book);
    }

    sub update_book($self) {
      my $book = $self->model("Book")->find($self->param('id'));
      my $data = $self->transfig->json;

      $book->author->update(delete($data->{author}));
      $book->update($data);
      $book->discard_changes;
      $self->render(json => $book);
    }

# DESCRIPTION

This plugin is an adapter to make [Data::Transfigure](https://metacpan.org/pod/Data%3A%3ATransfigure) a bit more convenient to
use in [Mojolicious](https://metacpan.org/pod/Mojolicious) applications. Two transfigurators are created for you:
one for data input, and the other for output. The default output transfigurator
is automatically invoked when rendering data via any of the methods configured
as ["renderers"](#renderers). The default input transfigurator is manually invoked by 
calling the [transfig.json](https://metacpan.org/pod/transfig.json) helper rather than, e.g., `$c->req->json`.

# METHODS

[Mojolicious::Plugin::Data::Transfigure](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AData%3A%3ATransfigure) inherits all methods from 
[Mojolicious::Plugin](https://metacpan.org/pod/Mojolicious%3A%3APlugin) and implements the following new ones

## register

Register the plugin in a Mojolicious application. Configuration via named 
arguments:

#### bare

Configures the default input and output transfigurators to be initialized with
no transfigurations instead of their usual default sets.

#### prefix

Configures the prefix used for the module's Mojolicious helper functions. This 
documentation assumes that it is left unchanged

Default: `transfig`

#### renderers

Controls which output rendering functions (e.g., `text`, `json`) are 
intercepted and automatically transfigured before being delivered to the client

Default: `['json']`

# HELPERS

## transfig.input

    app->transfig->input

Returns the default input transfigurator. Add transfigurations to it by calling
`add_transfigurator()`/`add_transfigurator_at()` on the return value.

By default, the following transfigurators are configured, unless the ["bare"](#bare)
configuration option is enabled:

- [Data::Transfigure::Default::ToString](https://metacpan.org/pod/Data%3A%3ATransfigure%3A%3ADefault%3A%3AToString)
- [Data::Transfigure::HashKeys::SnakeCase](https://metacpan.org/pod/Data%3A%3ATransfigure%3A%3AHashKeys%3A%3ASnakeCase)

## transfig.output

    app->transfig->output

Returns the default output transfigurator. Add transfigurations to it by calling
`add_transfigurator()`/`add_transfigurator_at()` on the return value.

By default, the following transfigurators are configured, unless the ["bare"](#bare)
configuration option is enabled:

- [Data::Transfigure::Default::ToString](https://metacpan.org/pod/Data%3A%3ATransfigure%3A%3ADefault%3A%3AToString)
- [Data::Transfigure::HashKeys::CamelCase](https://metacpan.org/pod/Data%3A%3ATransfigure%3A%3AHashKeys%3A%3ACamelCase)
- [Data::Transfigure::HashKeys::CapitalizedIDSuffix](https://metacpan.org/pod/Data%3A%3ATransfigure%3A%3AHashKeys%3A%3ACapitalizedIDSuffix)
- [Data::Transfigure::HashFilter::Undef](https://metacpan.org/pod/Data%3A%3ATransfigure%3A%3AHashFilter%3A%3AUndef)
- [Data::Transfigure::Tree::Merge](https://metacpan.org/pod/Data%3A%3ATransfigure%3A%3ATree%3A%3AMerge)
- [Data::Transfigure::Type::DBIx::Recursive](https://metacpan.org/pod/Data%3A%3ATransfigure%3A%3AType%3A%3ADBIx%3A%3ARecursive)

## transfig.json

    app->transfig->json
    app->transfig->json(transfigurator => $t)

Returns the request body, decoded as JSON, and passed through the `input`
transfigurator. ["transfig.input"](#transfig-input) is used by default, but an alternative
transfigurator may be passed in via the `transfigurator` argument.

# AUTHOR

Mark Tyrrell `<mark@tyrrminal.dev>`

# LICENSE

Copyright (c) 2024 Mark Tyrrell

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
