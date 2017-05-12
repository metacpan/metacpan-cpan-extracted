package Mojolicious::Plugin::XslateRenderer;

use strict;
use warnings;
use parent qw(Mojolicious::Plugin);

use MojoX::Renderer::Xslate;

sub register {
    my ($self, $app, $args) = @_;

    $args ||= {};

    my $xslate = MojoX::Renderer::Xslate->build(app => $app, %$args);
    $app->renderer->add_handler(tx => $xslate);
}


1;

__END__

=head1 NAME

Mojolicious::Plugin::XslateRenderer - Text::Xslate plugin

=head1 SYNOPSIS

    # Mojolicious
    $self->plugin('xslate_renderer');
    $self->plugin(xslate_renderer => {
        template_options => { syntax => 'TTerse', ...}
    });

    # Mojolicious::Lite
    plugin 'xslate_renderer';
    plugin xslate_renderer => {
        template_options => { syntax => 'TTerse', ...}
    };

=head1 DESCRIPTION

L<Mojolicous::Plugin::XslateRenderer> is a simple loader for
L<MojoX::Renderer::Xslate>.

=head1 METHODS

L<Mojolicious::Plugin::XslateRenderer> inherits all methods from
L<Mojolicious::Plugin> and overrides the following ones:

=head2 register

    $plugin->register

Registers renderer in L<Mojolicious> application.

=head1 SEE ALSO

L<MojoX::Renderer::Xslate>, L<Mojolicious>

=cut
