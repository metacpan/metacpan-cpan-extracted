package Mojolicious::Plugin::Data::Transfigure 0.01;
use v5.26;

# ABSTRACT: Mojolicious adapter for Data::Transfigure

use Mojo::Base 'Mojolicious::Plugin';

use Data::Transfigure;
use List::Util qw(any);
use Readonly;

Readonly::Scalar my $DEFAULT_PREFIX => 'transfig';

use experimental qw(signatures);

sub register($self, $app, $conf) {
  my @renderers = ($conf->{renderers} // [qw(json)])->@*;
  my $prefix    = $conf->{prefix} // $DEFAULT_PREFIX;
  my $bare      = $conf->{bare};

  # default OUTPUT transfigurator
  my $t_out = $bare ? Data::Transfigure->bare() : Data::Transfigure->dbix();
  $t_out->add_transfigurators(
    qw(
      Data::Transfigure::HashKeys::CamelCase
      Data::Transfigure::HashKeys::CapitalizedIDSuffix
      Data::Transfigure::HashFilter::Undef
      Data::Transfigure::Tree::Merge
      )
    )
    unless ($bare);

  # default INPUT transfigurator
  my $t_in = $bare ? Data::Transfigure->bare() : Data::Transfigure->new();
  $t_in->add_transfigurators(
    qw(
      Data::Transfigure::HashKeys::SnakeCase
      )
    )
    unless ($bare);

  # helpers to provide access to default transfigurators (for adding transfigurations)
  $app->helper("$prefix.input"  => sub($c) {$t_in});
  $app->helper("$prefix.output" => sub($c) {$t_out});

  # helper to apply transfigurator (default or custom) to request body JSON
  $app->helper(
    "$prefix.json" => sub($c, %args) {
      my $lt   = exists($args{transfigurator}) ? delete($args{transfigurator}) : $t_in;
      my $data = $c->req->json;
      return defined($lt) ? $lt->transfigure($data) : $data;
    }
  );

  # Render hook to apply transfigurator (default or custom) to request output
  $app->hook(
    before_render => sub ($c, $args) {
      my $lt = exists($args->{transfigurator}) ? delete($args->{transfigurator}) : $t_out;
      foreach my $k (keys($args->%*)) {
        if (defined($lt) && any {$_ eq $k} @renderers) {
          $args->{$k} = $lt->transfigure($args->{$k});
        }
      }
    }
  );
}

=head1 NAME

Mojolicious::Plugin::Data::Transfigure - Mojolicious adapter for Data::Transfigure

=head1 SYNOPSIS

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

=head1 DESCRIPTION

This plugin is an adapter to make L<Data::Transfigure> a bit more convenient to
use in L<Mojolicious> applications. Two transfigurators are created for you:
one for data input, and the other for output. The default output transfigurator
is automatically invoked when rendering data via any of the methods configured
as L</renderers>. The default input transfigurator is manually invoked by 
calling the L<transfig.json> helper rather than, e.g., C<$c-E<gt>req-E<gt>json>.

=head1 METHODS

L<Mojolicious::Plugin::Data::Transfigure> inherits all methods from 
L<Mojolicious::Plugin> and implements the following new ones

=head2 register

Register the plugin in a Mojolicious application. Configuration via named 
arguments:

=head4 bare

Configures the default input and output transfigurators to be initialized with
no transfigurations instead of their usual default sets.

=head4 prefix

Configures the prefix used for the module's Mojolicious helper functions. This 
documentation assumes that it is left unchanged

Default: C<transfig>

=head4 renderers

Controls which output rendering functions (e.g., C<text>, C<json>) are 
intercepted and automatically transfigured before being delivered to the client

Default: C<['json']>

=head1 HELPERS

=head2 transfig.input

  app->transfig->input

Returns the default input transfigurator. Add transfigurations to it by calling
C<add_transfigurator()>/C<add_transfigurator_at()> on the return value.

By default, the following transfigurators are configured, unless the L</bare>
configuration option is enabled:

=over

=item * L<Data::Transfigure::Default::ToString>

=item * L<Data::Transfigure::HashKeys::SnakeCase>

=back

=head2 transfig.output

  app->transfig->output

Returns the default output transfigurator. Add transfigurations to it by calling
C<add_transfigurator()>/C<add_transfigurator_at()> on the return value.

By default, the following transfigurators are configured, unless the L</bare>
configuration option is enabled:

=over

=item * L<Data::Transfigure::Default::ToString>

=item * L<Data::Transfigure::HashKeys::CamelCase>

=item * L<Data::Transfigure::HashKeys::CapitalizedIDSuffix>

=item * L<Data::Transfigure::HashFilter::Undef>

=item * L<Data::Transfigure::Tree::Merge>

=item * L<Data::Transfigure::Type::DBIx::Recursive>

=back

=head2 transfig.json

  app->transfig->json
  app->transfig->json(transfigurator => $t)

Returns the request body, decoded as JSON, and passed through the C<input>
transfigurator. L</transfig.input> is used by default, but an alternative
transfigurator may be passed in via the C<transfigurator> argument.

=head1 AUTHOR

Mark Tyrrell C<< <mark@tyrrminal.dev> >>

=head1 LICENSE

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

=cut

1;

__END__
