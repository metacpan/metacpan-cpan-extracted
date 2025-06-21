package Reactive::Mojo::Plugin;

use 5.006;
use strict;
use warnings;

use Mojo::Base 'Mojolicious::Plugin';

use Mojo::ByteStream;

use Reactive::Core;
use Reactive::Mojo::TemplateRenderer;

=head1 NAME

Reactive::Mojo::Plugin - Mojolicious plugin for Reactive

=head1 VERSION

Version 0.103

=cut

our $VERSION = '0.103';


=head1 SYNOPSIS

Register the plugin in startup method of your Mojolicious App

It takes `namespaces` configuration param which should be an arrayref of the namespaces within your app to scan for Reactive components

sub startup ($self) {
    ...
    $self->secrets($config->{secrets});

    $self->plugin(
        'Reactive::Mojo::Plugin',
        {
            namespaces => [
                'My::App::Components',
            ],
        },
    );
    ...

Then within you templates you can use a component like

<%= reactive('Counter') %>

or if there is initial state you want to set

<%= reactive('Counter', value => 10) %>

add the required JS with
<%= reactive_js %>

see Reactive::Core and Reactive::Examples for more information about creating components

=cut

=head2 register($self, Mojolicious $app, HashRef $conf)
    This register method is not expected to be called directly via userland code
    but instead will be called by Mojoicious when adding the plugin

    $self->plugin(
        'Reactive::Mojo::Plugin',
        {
            namespaces => [
                'My::App::Components',
            ],
        },
    );
=cut
sub register {
    my $self = shift;
    my $app = shift;
    my $conf = shift;

    my $renderer = Reactive::Mojo::TemplateRenderer->new(
        app => $app,
    );

    my $reactive = Reactive::Core->new(
        template_renderer => $renderer,
        secret => $app->secrets->[0],
        component_namespaces => $conf->{namespaces} // [],
    );

    $app->helper(reactive => sub {
        my ($c, $component, %args) = @_;

        return $reactive->initial_render($component, %args);
    });

    $app->helper(reactive_js => sub {
        my $c = shift;

        my $block = <<'HTML';
    <script defer src="https://cdn.jsdelivr.net/npm/@alpinejs/morph@3.x.x/dist/cdn.min.js"></script>
    <script defer src="https://cdn.jsdelivr.net/npm/alpinejs@3.x.x/dist/cdn.min.js"></script>
    <script src="/assets/reactive.js"></script>
HTML
        return Mojo::ByteStream->new($block);
    });

    $app->routes->get('/assets/reactive.js' => sub {
        my $c = shift;

        my $path = $INC{'Reactive/Core.pm'};
        $path =~ s/Core.pm$/reactive.js/;

        $c->res->headers->content_type('application/javascript');
        $c->reply->file($path);
    });

    $app->routes->post('/reactive' => sub {
        my $c = shift;

        my $data = $c->req->json;

        $c->render(
            json => $reactive->process_request($data)
        );
    });
}

=head1 AUTHOR

Robert Moore, C<< <robert at r-moore.tech> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-reactive-mojo at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Reactive-Mojo>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Reactive::Mojo::Plugin


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Reactive-Mojo>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Reactive-Mojo>

=item * Search CPAN

L<https://metacpan.org/release/Reactive-Mojo>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2025 by Robert Moore.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Reactive::Mojo
