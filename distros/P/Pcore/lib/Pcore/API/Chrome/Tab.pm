package Pcore::API::Chrome::Tab;

use Pcore -class, -res;
use Pcore::Util::Data qw[to_json from_json from_b64];
use Pcore::Util::Scalar qw[weaken];
use Pcore::WebSocket::raw;

use overload    #
  '&{}' => sub ( $self, @ ) {
    return sub {
        return $self->_call(@_);
    };
  },
  fallback => undef;

has chrome => ( required => 1 );
has id     => ( required => 1 );
has close_on_destroy => 1;

has listen => ();    # {method => callback} hook

has _components => ( init_arg => undef );

has _ws  => ();                                              # websocket connection
has _cb  => ();                                              # { msgid => callback }
has _sem => sub { Coro::Semaphore->new(1) }, is => 'lazy';

our $_MSG_ID = 0;

sub DESTROY ($self) {
    if ( ${^GLOBAL_PHASE} ne 'DESTRUCT' ) {
        my $url = "http://$self->{chrome}->{listen}->{host_port}/json/close/$self->{id}";

        Coro::async_pool sub ($url) { P->http->get($url) }, $url;
    }

    return;
}

sub new_tab ( $self, @args ) {
    $self->{chrome}->new_tab(@args);

    return;
}

sub reload_pac ( $self ) {
    $self->{chrome}->reload_pac;

    return;
}

sub close ( $self ) {    ## no critic qw[Subroutines::ProhibitBuiltinHomonyms NamingConventions::ProhibitAmbiguousNames]
    return P->http->get("http://$self->{chrome}->{listen}->{host_port}/json/close/$self->{id}");
}

sub activate ( $self ) {
    return P->http->get("http://$self->{chrome}->{listen}->{host_port}/json/activate/$self->{id}");
}

sub listen ( $self, $event, $cb = undef ) {    ## no critic qw[Subroutines::ProhibitBuiltinHomonyms]
    if ($cb) {
        $self->{listen}->{$event} = $cb;
    }
    else {
        return delete $self->{listen}->{$event};
    }

    return;
}

sub _call ( $self, $method, $args = undef ) {
    my $h = $self->{_ws} // $self->_connect;

    my $id = $_MSG_ID++;

    my $cv = P->cv;

    $self->{_cb}->{$id} = $cv;

    $self->{_ws}->send_text(
        \to_json {
            id     => $id,
            method => $method,
            params => $args,
        }
    );

    return $cv->recv;
}

sub _connect ( $self ) {
    weaken $self;

    my $guard = $self->_sem->guard;

    return $self->{_ws} ||= Pcore::WebSocket::raw->connect(
        "ws://$self->{chrome}->{listen}->{host_port}/devtools/page/$self->{id}",
        connect_timeout  => 1000,
        max_message_size => 0,
        compression      => 0,
        on_disconnect    => sub ( $ws ) {
            return if ${^GLOBAL_PHASE} eq 'DESTRUCT';

            undef $self->{_ws};

            # call pending callbacks
            if ( my $callbacks = delete $self->{_cb} ) {
                for my $cb ( values $callbacks->%* ) {
                    $cb->( res 500 );
                }
            }

            # call pending events callbacks
            for my $cb ( values $self->{listen}->%* ) {
                $cb->( undef, undef );
            }

            return;
        },
        on_text => sub ( $ws, $data_ref ) {
            my $msg = from_json $data_ref;

            if ( exists $msg->{id} ) {
                if ( my $cb = delete $self->{_cb}->{ $msg->{id} } ) {
                    my $res;

                    if ( my $error = $msg->{error} ) {
                        $res = res [ 400, $error->{message} ], $msg->{result};
                    }
                    else {
                        $res = res 200, $msg->{result};
                    }

                    $cb->($res);
                }
            }
            elsif ( $msg->{method} ) {
                if ( my $cb = $self->{listen}->{ $msg->{method} } ) {
                    $cb->( $msg->{method}, $msg->{params} );
                }
            }
            else {
                die $msg;
            }

            return;
        },
    );
}

# COMPONENTS
sub is_enabled ( $self, $component ) {
    return $self->{_components}->{$component};
}

sub enable ( $self, $component ) {
    return res 200 if $self->{_components}->{$component};

    my $res = $self->_call("$component.enable");

    $self->{_components}->{$component} = 1 if $res;

    return $res;
}

sub disable ( $self, $component ) {
    return res 200 if !$self->{_components}->{$component};

    my $res = $self->_call("$component.disable");

    $self->{_components}->{$component} = 0 if $res;

    return $res;
}

# NETWORK
sub network_enable ( $self ) {
    return $self->enable('Network');
}

sub network_disable ( $self ) {
    return $self->disable('Network');
}

# PAGE
sub page_enable ( $self ) {
    return $self->enable('Page');
}

sub page_disable ( $self ) {
    return $self->disable('Page');
}

# RUNTIME
sub runtime_enable ( $self ) {
    return $self->enable('Runtime');
}

sub runtime_disable ( $self ) {
    return $self->disable('Runtime');
}

# DOM
sub dom_enable ( $self ) {
    return $self->enable('DOM');
}

sub dom_disable ( $self ) {
    return $self->disable('DOM');
}

# COOKIES
sub get_cookies ( $self ) {
    my $res = $self->_call('Network.getCookies');

    my $cookies;

    if ( !$res ) {
        warn $res;
    }
    else {
        $cookies = $self->convert_cookies( $res->{data}->{cookies} );
    }

    return $cookies;
}

sub convert_cookies ( $self, $chrome_cookies ) {
    my $cookies;

    for my $cookie ( $chrome_cookies->@* ) {
        $cookies->{ $cookie->{domain} }->{ $cookie->{path} }->{ $cookie->{name} } = $cookie;

        $cookie->{val} = delete $cookie->{value};

        delete $cookie->{expires} if $cookie->{expires} && $cookie->{expires} < 0;
    }

    return $cookies;
}

# format, png, jpeg
# quality, 0 .. 100, for jpeg only
# clip, { x, y, width, height, scale }
sub get_screenshot ( $self, %args ) {
    if ( delete $args{full} ) {
        my $metrics = $self->_call('Page.getLayoutMetrics');

        my $res = $self->_call(
            'Emulation.setVisibleSize',
            {   width  => $metrics->{data}->{contentSize}->{width},
                height => $metrics->{data}->{contentSize}->{height}
            }
        );
    }

    my $res = $self->_call( 'Page.captureScreenshot', \%args, );

    my $img;

    if ($res) {
        $img = from_b64 $res->{data}->{data};
    }
    else {
        warn $res;
    }

    return $img;
}

# TODO !!! "Page.loadEventFired" is not fired
sub navigate_to ( $self, $url, %args ) {
    my $listener     = $self->{listen}->{'Page.loadEventFired'};
    my $page_enabled = $self->is_enabled('Page');

    my $res;

    if ( !$page_enabled ) {
        $res = $self->page_enable;

        return $res if !$res;
    }

    my $cv = P->cv;

    $self->listen( 'Page.loadEventFired', $cv );

    $res = $self->_call( 'Page.navigate', { url => $url, %args } );

    goto CLEANUP if !$res;

    $cv->recv;

  CLEANUP:
    $self->page_disable if !$page_enabled;
    $self->listen( 'Page.loadEventFired', $listener );

    return $res;
}

sub type_str ( $self, $str, $min_delay = 0.1, $max_delay = 0.3 ) {
    for my $char ( split //sm, $str ) {
        $self->_call(
            'Input.dispatchKeyEvent',
            {   type => 'char',
                text => $char,
            }
        );

        Coro::sleep $min_delay + rand( $max_delay - $min_delay );
    }

    return;
}

sub wait_for_selector ( $self, $selector, $timeout = 10 ) {
    my $res = $self->runtime_enable;

    my $args = {
        selector       => $selector,
        timeout        => $timeout * 1000,
        check_interval => 100,
    };

    my $json = P->data->to_json($args);

    $res = $self->_call(
        'Runtime.evaluate',
        {   returnByValue => \1,
            awaitPromise  => \1,
            expression    => <<"JS",
( async function ( args ) {
    while ( 1 ) {
        const el = document.querySelector( args.selector );

        // found
        if ( el ) {
            return { found: true };
        }

        if ( args.timeout <= 0 ) {
            return { found: false };
        }

        await new Promise( ( r ) => setTimeout( r, args.check_interval ) );

        args.timeout -= args.check_interval;
    }
} )( $json );
JS
        }
    );

    if ($res) {
        return $res->{data}->{result}->{value}->{found} ? res 200 : res 404;
    }
    else {
        return $res;
    }
}

sub attach_util ( $self, $source_url = undef ) {
    my $res = $self->runtime_enable;

    $source_url //= 'https://www.google.com/util.js';

    state $script = P->file->read_bin( $ENV->{share}->get('/Pcore/data/chrome/util.js') );

    $res = $self->_call(
        'Runtime.compileScript',
        {   expression    => $script,
            sourceURL     => $source_url,
            persistScript => \1,
        }
    );

    return $res if !$res;

    $res = $self->_call( 'Runtime.runScript', { scriptId => $res->{data}->{scriptId}, } );

    return $res;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 301                  | Subroutines::ProhibitManyArgs - Too many arguments                                                             |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::API::Chrome::Tab

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
