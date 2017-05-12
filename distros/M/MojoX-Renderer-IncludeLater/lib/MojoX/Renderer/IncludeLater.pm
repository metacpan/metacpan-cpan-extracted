package MojoX::Renderer::IncludeLater;

our $VERSION = '0.02';

use Mojo::Base 'Mojolicious::Plugin';

our $counter = 0;

sub register {
    my ($self, $app) = @_;

    $app->helper(include_later => sub {
      my ($self, $template) = (shift, shift);
      my $args = scalar @_ % 2 == 0 ? { @_ } : shift;
      my $key  = "\0IL\0" . ++$counter . "\0";

      $self->stash->{'mojo.x.include_later'}->{$key} = [ $template, $args ];
      return $key;
    });

    $app->hook(after_render => sub {
      my ($self, $output, $format) = @_;
      while(my ($id) = $$output =~ /(\0IL\0\d+\0)/m) {
        my ($template, $args) = @{$self->stash->{'mojo.x.include_later'}->{$id}};
        my ($op, $format) = $app->renderer->render($self, { partial => 1, template => $template, $args ? %$args : () });
        warn "Error rendering include_later" if !$op;
        $id = quotemeta $id;
        $$output =~ s/$id/$op/m;
      }
    });
}

1;

=encoding utf8

=head1 NAME

MojoX::Renderer::IncludeLater - A post processor to defer partial template rendering

=head1 DESCRIPTION

L<MojoX::Renderer::IncludeLater> is a L<Mojolicious> plugin which adds support for
deferring rendering of partial templates until the parent template rendering is complete.

For example, this makes it possible to build up data during rendering (e.g. which
input fields are rendered) and then use that data to render an earlier part of a template.

This should work with any L<Mojolicious> renderer, including L<Mojolicious::Renderer> and
L<Mojolicious::Renderer::Xslate>.

=head1 SYNOPSIS

Example 'test' template:

    % stash('my_var') // 'my_var has not been set'

Example page template:

    <h3>Include later</h3>
    <p>Include a template immediately</p>
    % include "test" # will render 'my_var has not been set'

    <p>Include a template later</p>
    % include_later "test" # will render 'foo'

    <p>Set a value the included template expects</p>
    % stash('test' => 'foo')

Which will generate the following output:

    <h3>Include later</h3>
    <p>Include a template immediately</p>
    my_var has not been set

    <p>Include a template later</p>
    foo

    <p>Set a value the included template expects</p>

=head1 HELPERS

This plugin creates the following L<Mojolicious> helpers:

=head2 include_later

Is identical to C<include> but template inclusion happens after
the rest of the template has been rendered.

=head1 HOOKS

This plugin hooks into C<after_render> to perform deferred template inclusion.

=head1 SEE ALSO

L<Mojolicious>

=cut

