package Mojolicious::Plugin::Template::Mustache;
use Mojo::Base 'Mojolicious::Plugin';

use Template::Mustache;

our $VERSION = '0.03';

sub register {
    my (undef, $app, $args) = @_;

    $args //= {};

    $app->renderer->add_handler(mustache => sub {
        my Mojolicious::Renderer $renderer = shift;
        my Mojolicious::Controller $c = shift;
        my ($output, $options) = @_;

        if ($options->{inline} and (my $inline_template = $options->{inline})) {
            my $mustache = Template::Mustache->new(
                   template => $inline_template,
               );
            $$output = $mustache->render($c->stash);
        }
        elsif (my $template_name = $renderer->template_path($options)) {
            my $mustache = Template::Mustache->new(
                    template_path => $template_name
                );
            $$output = $mustache->render($c->stash);
        } else {
            my $data_template = $renderer->get_data_template($options);
            my $mustache = Template::Mustache->new(
                    template => $data_template
                );
            $$output = $mustache->render($c->stash) if $data_template;
        }
        return $$output ? 1 : 0;
    });

    return 1;
}

1;
__END__

=encoding utf8

=head1 NAME

Mojolicious::Plugin::Template::Mustache - Mojolicious Plugin

=head1 SYNOPSIS

  # Mojolicious
  $self->plugin('Template::Mustache');

  # Mojolicious::Lite
  plugin 'Template::Mustache';

  get '/inline' => sub {
  my $c = shift;
  $c->render(
      handler => 'mustache',
      inline  => 'Inline hello, {{message}}!',
      message => 'Mustache',
  );
};

=head1 DESCRIPTION

L<Mojolicious::Plugin::Template::Mustache> is a L<Mojolicious> plugin.

=head1 METHODS

L<Mojolicious::Plugin::Template::Mustache> inherits all methods from L<Mojolicious::Plugin>.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicious.org>, L<http://mustache.github.io>, L<Template::Mustache>.

=head2 AUTHOR

Cyrill Novgorodcev E<lt>cynovg@cpan.orgE<gt>

=head2 LICENSE

                    Copyright 2017 Cyrill Novgorodcev.

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut

