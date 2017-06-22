package Mojolicious::Plugin::Text::Caml;
use Mojo::Base 'Mojolicious::Plugin';

use Text::Caml;

our $VERSION = '0.03';

sub register {
  my ($self, $app, $args) = @_;

    $args //= {};
    my $caml = Text::Caml->new(%$args);

    $app->renderer->add_handler(caml => sub {
        my ($renderer, $c, $output, $options) = @_;

        if ($options->{inline}) {
            my $inline_template = $options->{inline};
            $$output = $caml->render($inline_template, $c->stash);
        }
        elsif (my $template_name = $renderer->template_path($options)) {
            $caml->set_templates_path($renderer->paths->[0]);
            $$output = $caml->render_file($template_name, $c->stash);
        } else {
            my $data_template = $renderer->get_data_template($options);
            $$output = $caml->render($data_template, $c->stash) if $data_template;
        }
        return $$output ? 1 : 0;
    });

    return 1;
}

1;
__END__

=encoding utf8

=head1 NAME

Mojolicious::Plugin::Text::Caml - Mojolicious Plugin

=head1 SYNOPSIS

  plugin 'Text::Caml';

  get '/inline' => sub {
    my $c = shift;
    $c->render(handler => 'caml', inline  => 'Hello, {{message}}!', message => 'Mustache');
  };

=head1 DESCRIPTION

L<Mojolicious::Plugin::Text::Caml> is a L<Mojolicious> plugin.

=head1 METHODS

L<Mojolicious::Plugin::Text::Caml> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 register

  # Mojolicious
  $self->plugin('Text::Caml');

  # Mojolicious::Lite
  plugin 'Text::Caml';

Register plugin in L<Mojolicious> application.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicious.org>, L<http://mustache.github.io>, L<Text::Caml>.

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
