package Mojolicious::Plugin::CachePurge;
use Mojo::Base 'Mojolicious::Plugin';
use Mojo::URL;

our $VERSION = '0.01';

has 'ua' => sub { Mojo::UserAgent->new; };

sub register {
    my ( $self, $app, $conf ) = @_;

    if ( defined( $conf->{baseurl} ) ) {
        $app->log->error("CachePurge: Can not parse baseurl as url, aborting")
          unless ( $self->{'baseurl'} = Mojo::URL->new( $conf->{'baseurl'} ) );
    }
    else {
        $app->log->error("CachePurge: No baseurl configured, aborting");
    }

    if ( $self->{'baseurl'} ) {
        $self->_add_log_hooks($app);
        $app->helper( 'cache_purge' => sub { $self->_purge(@_) } );
    }
    else {
        $app->helper( 'cache_purge' =>
              sub { $app->log->debug('CachePurge: inactive, config error') } );
    }

    return $self;
}

sub _add_log_hooks {
    my ( $self, $app ) = @_;

    $self->ua->on(
        start => sub {
            my ( $ua, $tx ) = @_;
            my $msg =
                "CachePurge: request, method="
              . $tx->req->method
              . ", url="
              . $tx->req->url;
            $app->log->debug($msg);
        },
        error => sub {
            my ( $ua, $err ) = @_;
            $app->log->error( "CachePurge: " . $err );
        }
    );

}

sub _purge {
    my ( $self, $c, $args, $cb ) = @_;

    # We may get a callback, but no args. It will be here as $args, so
    # we move it.
    if (ref $args eq 'CODE') {
        $cb = $args;
        undef $args;
    }

    my $purge_path = $args->{'path'} ||= $c->req->url->path;

    my $purge_url = Mojo::URL->new( $self->{'baseurl'} )->path($purge_path);

    Mojo::IOLoop->delay(
        sub {
            my ($delay) = @_;
            my $tx = $self->ua->build_tx( PURGE => $purge_url );
            $self->ua->start( $tx => $delay->begin );
        },

        # log response
        sub {
            my ( $delay, $tx ) = @_;
            $c->app->log->debug( "CachePurge: response, url="
                  . $tx->req->url
                  . ", code="
                  . $tx->res->code );
            $delay->pass($tx);
        },

        # handle callback, if any
        sub {
            my ( $delay, $tx ) = @_;
            $self->$cb($tx) if ($cb);
        }
    );
}

1;
__END__

=encoding utf8

=head1 NAME

Mojolicious::Plugin::CachePurge - Mojolicious Plugin to purge content from front end HTTP cache

=head1 SYNOPSIS

  # Mojolicious
  $self->plugin('CachePurge' => {baseurl = 'http://example.com'});

  # Mojolicious::Lite
  plugin 'CachePurge' => {baseurl = 'http://example.com'};

=head1 DESCRIPTION

L<Mojolicious::Plugin::CachePurge> is a L<Mojolicious> plugin to send
cache invalidation requests to a web application accelerator like
L<Varnish>, or any other front end HTTP cache supporting PURGE
requests.

Cache invalidation requests are non blocking.

=head1 METHODS

L<Mojolicious::Plugin::CachePurge> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 register

  $plugin->register(Mojolicious->new);

Register plugin in L<Mojolicious> application.

=head1 HELPERS

L<Mojolicious::Plugin::CachePurge> implements the following helpers

=head2 purge

    # Purge this path
    $app->purge;

    # Purge some other path
    $app->purge( { path => '/some/other/path' } );

    # Purge with callback.
    $app->purge(
        sub {
            my $tx = shift;
            ...
        }
    );

    # Purge with path and callback
    $app->purge(
        { path => '/this/must/be/gone' },
        sub {
            my $tx = shift;
            ...
        }
    );

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicio.us>.

=cut
