package Mojolicious::Plugin::Sticker;
$Mojolicious::Plugin::Sticker::VERSION = 'v0.0.2';
use Mojo::Base 'Mojolicious::Plugin';

sub register {
    my ( $self, $app, $child ) = @_;

    my $embed = Mojo::Server->new->load_app( $child->{app} );

    return $app->routes->add_child( $embed->routes );
}

1;

# ABSTRACT: turns baubles into trinkets

=pod

=encoding utf8

=head1 NAME

Mojolicious::Plugin::Sticker - Stick apps together

=head1 VERSION

0.0.2

=head1 SYNOPSIS

A simple Mojolicious plugin inspired by L<Mojolicious::Plugin::Mount>
to join several small mojo apps into a single one.

Differently from L<Mojolicious::Plugin::Mount> you won't provide a
prefix. The small apps an their routes are just glued together "as is".

It is like a C<cat> for mojo apps.

    # app foo.pl
    
    use Mojolicious::Lite -signarues;
    
    get '/foo' => sub($c) { $c->render( json => { foo => 123 } ) };
    
    app->start;

    ##################################################

    # app bar.pl
    
    use Mojolicious::Lite -signatures;
    
    get '/bar' => sub($c) { $c->render( json => { bar => 456 } ) };
    
    post '/baz' => sub($c) {
        my $baz  = $c->req->json->{baz} || 0;
    
        $c->render( json => { baz => $baz + 42 } );
    };
    
    app->start;
    
    ##################################################

    # app main.pl
    
    use Mojolicious::Lite;
    
    plugin Sticker => { app => 't/lib/apps/foo' };
    plugin Sticker => { app => 't/lib/apps/bar' };
    
    app->start;

    # main.pl does all that both foo.pl and bar.pl does

=head1 DESCRIPTION

Sometimes we have some small apps that we may want to glue together
into a bigger one. This is pretty straightforward with L<Mojolicious>.

L<Mojolicious::Plugin::Mount> is a very nice tool to add small apps
under a prefix into another app.

This plugin goes down to a slightly different approach. We just glue
the apps together keeping its original routes.

This is exclty what this plugin does:

    use Mojolicious::Lite -signtures;

    my $embed = Mojo::Server->new->load_app('my-app');
    app->routes->add_child( $embed->routes );


=head1 METHODS

L<Mojolicious::Plugin::Sticker> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 register

Mount an aplication and attach its routes as children of
main app routes.

=head1 SEE ALSO

L<Mojolicious>,
L<Mojolicious::Plugin::Mount>,
L<Mojolicious::Guides>,
L<https://mojolicious.org>.

=head1 AUTHOR

Blabos de Blebe, C<< <blabos at cpan.org> >>

=cut

