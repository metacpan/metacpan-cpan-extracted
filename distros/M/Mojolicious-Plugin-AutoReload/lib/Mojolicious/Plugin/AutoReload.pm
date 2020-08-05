package Mojolicious::Plugin::AutoReload;
our $VERSION = '0.010';
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
#pod =head1 THANKS
#pod
#pod Thanks to L<Grant Street Group|https://grantstreet.com> for funding
#pod continued development of this plugin!
#pod
#pod =cut

use Mojo::Base 'Mojolicious::Plugin';
use Mojo::IOLoop;
use Mojo::Util qw( unindent trim );

sub register {
    my ( $self, $app, $config ) = @_;
    # This number changes every time the server restarts, so a client
    # that hasn't tried pinging in a while can be told to reload.
    # Need to srand because Morbo forks, otherwise we will always get
    # the same nonce.
    my $nonce = srand && int rand( 2**16 );

    if ( $app->mode eq 'development' ) {
        $app->routes->websocket( '/auto_reload' => sub {
            my ( $c ) = @_;
            # Start the websocket
            $c->inactivity_timeout( 60 );
            my $timer_id = Mojo::IOLoop->recurring( 30, sub { $c->send( 'ping' ) } );
            $c->on( finish => sub {
                Mojo::IOLoop->remove( $timer_id );
            } );
        } );

        $app->hook( around_dispatch => sub {
            # Using a around_dispatch hook allows us to avoid logging
            # anything or doing anything when polling. This way we can
            # poll faster without making debugging harder.
            my ( $next, $c ) = @_;
            return $next->() if $c->req->url->path ne '/auto_reload'
                || $c->req->is_handshake;
            # Prevent Mojolicious from doing anything else with this
            # request.
            $c->stash( 'mojo.finished', 1 );
            $c->render_later;
            # Client is just looking for a response, but validate their
            # nonce first.
            if ( !$c->param( 'nonce' ) || $c->param( 'nonce' ) ne $nonce ) {
                return $c->rendered( 205 );
            }
            return $c->rendered( 204 );
        } );

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
            my $auto_reload_end_point = $c->url_for( 'auto_reload' )->path->leading_slash(1);
            my $mechanism = $ENV{PLACK_ENV} ? 'poll' : 'websocket';
            return unindent trim( <<"ENDHTML" );
                <style>
                @-webkit-keyframes auto-reload-spinner-border {
                    to {
                        -webkit-transform: rotate(360deg);
                        transform: rotate(360deg);
                    }
                }
                \@keyframes auto-reload-spinner-border {
                    to {
                        -webkit-transform: rotate(360deg);
                        transform: rotate(360deg);
                    }
                }

                .auto-reload-modal {
                    position: fixed;
                    top: 0;
                    left: 0;
                    height: 100vh;
                    width: 100vw;
                    margin: 0;
                    padding: 0;
                    border: none;
                    /* I would prefer a blur effect, but this is as good as I can get */
                    background: rgba( 255, 255, 255, 0.7 );
                    display: flex;
                    align-items: center;
                    justify-content: center;
                }

                .auto-reload-alert {
                    background: rgba( 255, 255, 255, 0.5 );
                    padding: 1.25rem 1.75rem;
                    border-radius: .25rem;
                    border: 2px solid grey;
                }

                .auto-reload-spinner {
                    display: inline-block;
                    width: 2em;
                    height: 2em;
                    vertical-align: middle;
                    border: .25em solid black;
                    border-right-color: transparent;
                    border-radius: 50%;
                    margin: .25em;
                    animation: auto-reload-spinner-border .75s linear infinite;
                }

                .auto-reload-text {
                    vertical-align: middle;
                }

                </style>
                <script>
                    var autoReloadUrl = "$auto_reload_end_point";
                    var mechanism = "$mechanism";
                    var nonce = "$nonce";

                    function openWebsocket() {
                        // If we lose our websocket connection, the web server must
                        // be restarting, and we should reload the page
                        var opened = false;
                        var proto = "ws";
                        if ( document.location.protocol === "https:" ) {
                            proto = "wss";
                        }
                        var autoReloadWs = new WebSocket( proto + "://" + location.host + autoReloadUrl );
                        autoReloadWs.addEventListener( "open", function (event) {
                            opened = true;
                        } );
                        autoReloadWs.addEventListener( "close", function (event) {
                            if ( !opened ) {
                                // This server doesn't support websockets, so try long-polling
                                runPoller();
                                return;
                            }
                            waitForRestart();
                        } );
                        // Send pings to ensure that the connection stays up, or we learn
                        // of the connection's death
                        setInterval( function () { autoReloadWs.send( "ping" ) }, 30000 );
                    }

                    // If opening a websocket doesn't work, try polling!
                    var POLL_INTERVAL = 2000;
                    var RESTART_INTERVAL = 100;
                    var pollTimer;
                    function runPoller() {
                        var request = new XMLHttpRequest();
                        request.timeout = POLL_INTERVAL;
                        request.open('GET', autoReloadUrl + '?nonce=' + nonce, true);
                        request.onreadystatechange = function () {
                            if (request.readyState == XMLHttpRequest.DONE ) {
                                if ( request.status == 204 /* NO CONTENT */ ) {
                                    pollTimer = setTimeout( runPoller, POLL_INTERVAL );
                                }
                                else {
                                    waitForRestart();
                                }
                            }
                        };
                        request.send();
                    }

                    function autoReload() {
                        location.reload(true);
                    }

                    // Start/stop the poller when we are not the active page to reduce
                    // the number of requests we're sending
                    if ( "visibilityState" in document ) {
                        document.addEventListener( 'visibilitychange', function () {
                            clearTimeout( pollTimer );
                            pollTimer = null;
                            if ( document.visibilityState == "visible" ) {
                                pollTimer = setTimeout( runPoller, 0 );
                            }
                        } );
                    }
                    else {
                        window.addEventListener( 'blur', function () {
                            clearTimeout( pollTimer );
                            pollTimer = null;
                        } );
                        window.addEventListener( 'focus', function () {
                            pollTimer = setTimeout( runPoller, 0 );
                        } );
                    }

                    var restartTimer;
                    function waitForRestart() {
                        var startTime = new Date();
                        var modal = document.createElement( 'div' );
                        modal.className = 'auto-reload-modal';

                        var alert = document.createElement( 'div' );
                        alert.className = 'auto-reload-alert';
                        // Spinner from Bootstrap
                        var spinner = document.createElement( 'div' );
                        spinner.className = 'auto-reload-spinner';
                        alert.appendChild( spinner );

                        var textSpan = document.createElement( 'span' );
                        textSpan.className = 'auto-reload-text';
                        textSpan.appendChild( document.createTextNode( 'Waiting for Restart...' ) );
                        alert.appendChild( textSpan );

                        var buttonBar = document.createElement( 'div' );

                        var reloadBtn = document.createElement( 'button' );
                        reloadBtn.className = 'btn btn-primary';
                        reloadBtn.appendChild( document.createTextNode( 'Reload' ) );
                        reloadBtn.addEventListener( 'click', autoReload );
                        buttonBar.appendChild( reloadBtn );

                        var stopBtn = document.createElement( 'button' );
                        stopBtn.className = 'btn btn-secondary';
                        stopBtn.appendChild( document.createTextNode( 'Cancel' ) );
                        stopBtn.addEventListener( 'click', function () {
                            clearTimeout( restartTimer );
                            document.body.removeChild( modal );
                        } );
                        buttonBar.appendChild( stopBtn );
                        alert.appendChild( buttonBar );

                        var warnDiv = document.createElement( 'div' );
                        warnDiv.style.visibility = 'hidden';
                        warnDiv.appendChild(
                            document.createTextNode(
                                'Server is taking a long time to restart. Is something wrong?'
                            )
                        );
                        alert.appendChild( warnDiv );

                        modal.appendChild( alert );
                        document.body.appendChild( modal );

                        var tryRequest = function () {
                            var now = new Date();
                            if ( now - startTime > 5000 ) {
                                warnDiv.style.visibility = 'visible';
                            }

                            var request = new XMLHttpRequest();
                            request.timeout = RESTART_INTERVAL;
                            request.open('GET', autoReloadUrl, true);
                            request.onreadystatechange = function () {
                                if (request.readyState == XMLHttpRequest.DONE ) {
                                    if ( request.status == 205 /* RESET CONTENT */ ) {
                                        autoReload();
                                    }
                                }
                            };
                            request.send();
                        };
                        restartTimer = setInterval( tryRequest, RESTART_INTERVAL );
                    }
                    window.addEventListener( 'beforeunload', function () {
                        if ( restartTimer ) {
                            clearTimeout( restartTimer );
                        }
                    });

                    if ( mechanism == 'websocket' ) {
                        openWebsocket();
                    }
                    else {
                        pollTimer = setTimeout( runPoller, POLL_INTERVAL );
                    }
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

version 0.010

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

=head1 THANKS

Thanks to L<Grant Street Group|https://grantstreet.com> for funding
continued development of this plugin!

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
