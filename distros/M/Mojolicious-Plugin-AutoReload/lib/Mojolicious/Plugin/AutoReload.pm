package Mojolicious::Plugin::AutoReload;
our $VERSION = '0.001';
# ABSTRACT: Automatically reload open browser windows when your application changes

#pod =head1 SYNOPSIS
#pod
#pod     use Mojolicious::Lite;
#pod     plugin AutoReload => {};
#pod     get '/' => 'index';
#pod     app->start;
#pod
#pod     __DATA__
#pod     @@ layouts/default.html.ep
#pod     %= auto_reload;
#pod     %= content;
#pod
#pod     @@ index.html.ep
#pod     % layout 'default';
#pod     Hello world!
#pod
#pod =head1 DESCRIPTION
#pod
#pod This plugin automatically reloades the page when the Mojolicious webapp
#pod restarts.  This is especially useful when using L<the Morbo development
#pod server|http://mojolicious.org/perldoc/Mojolicious/Guides/Tutorial#Reloading>,
#pod which automatically restarts the webapp when it detects changes.
#pod Combined, C<morbo> and C<Mojolicious::Plugin::AutoReload> will
#pod automatically display your new content whenever you change your webapp
#pod in your editor!
#pod
#pod This works by opening a WebSocket connection to a specific Mojolicious
#pod route. When the server restarts, the WebSocket is disconnected, which
#pod triggers a reload of the page.
#pod
#pod =head1 HELPERS
#pod
#pod =head2 auto_reload
#pod
#pod The C<auto_reload> template helper inserts the JavaScript to
#pod automatically reload the page. This helper only works when the
#pod application mode is C<development>, so you can leave this in all the
#pod time and have it only appear during local development.
#pod
#pod =head1 ROUTES
#pod
#pod =head2 /auto_reload
#pod
#pod This plugin adds a C</auto_reload> WebSocket route to your application.
#pod
#pod =head1 SEE ALSO
#pod
#pod L<Mojolicious>
#pod
#pod =cut

use Mojo::Base 'Mojolicious::Plugin';
use Mojo::IOLoop;
use Mojo::Util qw( unindent trim );

sub register {
    my ( $self, $app, $config ) = @_;

    $app->routes->websocket( '/auto_reload' => sub {
        my ( $c ) = @_;
        my $timer_id = Mojo::IOLoop->timer( 30, sub { $c->send( 'ping' ) } );
        $c->on( finish => sub {
            Mojo::IOLoop->remove( $timer_id );
        } );
    } )->name( 'auto_reload' );

    $app->helper( auto_reload => sub {
        my ( $c ) = @_;
        if ( $app->mode eq 'development' ) {
            return $c->render_to_string( inline => unindent trim( <<'ENDHTML' ) );
                <script>
                    // If we lose our websocket connection, the web server must
                    // be restarting, and we should reload the page
                    var autoReloadWs = new WebSocket( "ws://" + location.host + "<%== url_for( 'auto_reload' ) %>" );
                    autoReloadWs.addEventListener( "close", function (event) {
                        location.reload(true); // force a reload from the server
                    } );
                    // Send pings to ensure that the connection stays up, or we learn
                    // of the connection's death
                    setInterval( function () { autoReloadWs.send( "ping" ) }, 5000 );
                </script>
ENDHTML
        }
        return '';
    } );
}

1;

__END__

=pod

=head1 NAME

Mojolicious::Plugin::AutoReload - Automatically reload open browser windows when your application changes

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    use Mojolicious::Lite;
    plugin AutoReload => {};
    get '/' => 'index';
    app->start;

    __DATA__
    @@ layouts/default.html.ep
    %= auto_reload;
    %= content;

    @@ index.html.ep
    % layout 'default';
    Hello world!

=head1 DESCRIPTION

This plugin automatically reloades the page when the Mojolicious webapp
restarts.  This is especially useful when using L<the Morbo development
server|http://mojolicious.org/perldoc/Mojolicious/Guides/Tutorial#Reloading>,
which automatically restarts the webapp when it detects changes.
Combined, C<morbo> and C<Mojolicious::Plugin::AutoReload> will
automatically display your new content whenever you change your webapp
in your editor!

This works by opening a WebSocket connection to a specific Mojolicious
route. When the server restarts, the WebSocket is disconnected, which
triggers a reload of the page.

=head1 HELPERS

=head2 auto_reload

The C<auto_reload> template helper inserts the JavaScript to
automatically reload the page. This helper only works when the
application mode is C<development>, so you can leave this in all the
time and have it only appear during local development.

=head1 ROUTES

=head2 /auto_reload

This plugin adds a C</auto_reload> WebSocket route to your application.

=head1 SEE ALSO

L<Mojolicious>

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
