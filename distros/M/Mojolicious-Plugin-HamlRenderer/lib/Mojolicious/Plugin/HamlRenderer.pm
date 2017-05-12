package Mojolicious::Plugin::HamlRenderer;
our $VERSION = '2.100000';

use strict;
use warnings;

use base 'Mojolicious::Plugin';

use MojoX::Renderer::Haml;

sub register {
    my ($self, $app, $args) = @_;

    $args ||= {};

    my $haml = MojoX::Renderer::Haml->build(%$args, mojo => $app);

    # Add "haml" handler
    $app->renderer->add_handler(haml => $haml);
}

1;

=head1 NAME

Mojolicious::Plugin::HamlRenderer - Load HAML renderer

=head1 SYNOPSIS

    # lite app
    plugin 'haml_renderer';

    # or normal app
    $self->plugin('haml_renderer');

=head1 DESCRIPTION

Simple plugin to load HAML renderer into your Mojolicious app.

=head1 SEE ALSO

L<MojoX::Renderer::Haml>, L<Text::Haml>.

=cut
