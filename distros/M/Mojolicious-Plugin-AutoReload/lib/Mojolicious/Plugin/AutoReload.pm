package Mojolicious::Plugin::AutoReload;
our $VERSION = '0.007';
# ABSTRACT: Automatically reload open browser windows when your application changes

#pod =head1 SYNOPSIS
#pod
#pod     use Mojolicious::Lite;
#pod     plugin AutoReload => {};
#pod     get '/' => 'index';
#pod     app->start;
#pod     __DATA__
#pod     @@ index.html.ep
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
#pod The AutoReload plugin will automatically add a C<< <script> >> tag to
#pod your HTML pages while running in C<development> mode. If you need to
#pod control where this script tag is written, use the L</auto_reload>
#pod helper.
#pod
#pod To disable the plugin for a single page, set the C<<
#pod plugin.auto_reload.disable >> stash value to a true value:
#pod
#pod
#pod     get '/' => sub {
#pod         my ( $c ) = @_;
#pod         # Don't auto-reload the home page
#pod         $c->stash( 'plugin.auto_reload.disable' => 1 );
#pod         ...
#pod     };
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
#pod This is only needed if you want to control where the C<< <script> >>
#pod for automatically-reloading is rendered.
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

    if ( $app->mode eq 'development' ) {
        $app->routes->websocket( '/auto_reload' => sub {
            my ( $c ) = @_;
            $c->inactivity_timeout( 60 );
            my $timer_id = Mojo::IOLoop->recurring( 30, sub { $c->send( 'ping' ) } );
            $c->on( finish => sub {
                Mojo::IOLoop->remove( $timer_id );
            } );
        } )->name( 'auto_reload' );

        $app->hook(after_render => sub {
            my ( $c, $output, $format ) = @_;
            return if $c->stash( 'plugin.auto_reload.disable' );
            return if $format ne 'html';
            if ( my $reload = $c->auto_reload ) {
                # Try to add the auto-reload to the end of the body.
                # Not using Mojo::DOM because it causes bizarre errors
                # when trying to 'utf8::downgrade' in
                # Mojo::IOLoop::Stream:
                #   Mojo::Reactor::Poll: I/O watcher failed: Wide
                #   character in subroutine entry
                unless ( $$output =~ s{(</body)}{$reload$1} ) {
                    # Otherwise just append it, since the end will be
                    # the body
                    $$output .= $reload;
                }
            }
        });
    }

    $app->helper( auto_reload => sub {
        my ( $c ) = @_;
        if ( $app->mode eq 'development' && !$c->stash( 'plugin.auto_reload.disable' ) ) {
            $c->stash( 'plugin.auto_reload.disable' => 1 );
            my $auto_reload_end_point = $c->url_for( 'auto_reload' );
            return unindent trim( <<"ENDHTML" );
                <script>
                    // If we lose our websocket connection, the web server must
                    // be restarting, and we should reload the page
                    var proto = "ws";
                    if ( document.location.protocol === "https:" ) {
                        proto = "wss";
                    }
                    var autoReloadWs = new WebSocket( proto + "://" + location.host + "$auto_reload_end_point" );
                    autoReloadWs.addEventListener( "close", function (event) {
                        // Wait one second then force a reload from the server
                        setTimeout( function () { location.reload(true); }, 1000 );
                    } );
                    // Send pings to ensure that the connection stays up, or we learn
                    // of the connection's death
                    setInterval( function () { autoReloadWs.send( "ping" ) }, 30000 );
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

version 0.007

=head1 SYNOPSIS

    use Mojolicious::Lite;
    plugin AutoReload => {};
    get '/' => 'index';
    app->start;
    __DATA__
    @@ index.html.ep
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

The AutoReload plugin will automatically add a C<< <script> >> tag to
your HTML pages while running in C<development> mode. If you need to
control where this script tag is written, use the L</auto_reload>
helper.

To disable the plugin for a single page, set the C<<
plugin.auto_reload.disable >> stash value to a true value:

    get '/' => sub {
        my ( $c ) = @_;
        # Don't auto-reload the home page
        $c->stash( 'plugin.auto_reload.disable' => 1 );
        ...
    };

=head1 HELPERS

=head2 auto_reload

The C<auto_reload> template helper inserts the JavaScript to
automatically reload the page. This helper only works when the
application mode is C<development>, so you can leave this in all the
time and have it only appear during local development.

This is only needed if you want to control where the C<< <script> >>
for automatically-reloading is rendered.

=head1 ROUTES

=head2 /auto_reload

This plugin adds a C</auto_reload> WebSocket route to your application.

=head1 SEE ALSO

L<Mojolicious>

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 CONTRIBUTORS

=for stopwords Robert DeRose Zeeshan Muhammad

=over 4

=item *

Robert DeRose <RobertDeRose@users.noreply.github.com>

=item *

Zeeshan Muhammad <zeeshan@dkhr.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
