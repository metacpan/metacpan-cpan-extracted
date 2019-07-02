package Pcore::Chrome::Tab;

use Pcore -class, -res;
use Pcore::Util::Data qw[to_json from_json from_b64];
use Pcore::Util::Scalar qw[weaken is_plain_coderef];
use Pcore::WebSocket::raw;

use overload    #
  q[&{}] => sub ( $self, @ ) {
    return sub {
        my $cb = is_plain_coderef $_[-1] ? pop @_ : undef;

        return $self->_call( shift, {@_}, $cb );
    };
  },
  fallback => undef;

has chrome => ( required => 1 );
has id     => ( required => 1 );

has listen => ();    # {method => callback} hook

has network_enabled => ( 0, init_arg => undef );
has page_enabled    => ( 0, init_arg => undef );

has _ws => ();       # websocket connection
has _cb => ();       # { msgid => callback }

our $_MSG_ID = 0;

sub new_tab ( $self, @args ) {
    $self->{chrome}->new_tab(@args);

    return;
}

sub close ( $self ) {    ## no critic qw[Subroutines::ProhibitBuiltinHomonyms NamingConventions::ProhibitAmbiguousNames]
    return P->http->get("http://$self->{chrome}->{host}:$self->{chrome}->{port}/json/close/$self->{id}");
}

sub activate ( $self ) {
    return P->http->get("http://$self->{chrome}->{host}:$self->{chrome}->{port}/json/activate/$self->{id}");
}

sub listen ( $self, $event, $cb = undef ) {    ## no critic qw[Subroutines::ProhibitBuiltinHomonyms]
    if ($cb) {
        $self->{listen}->{$event} = $cb;
    }
    else {
        delete $self->{listen}->{$event};
    }

    return;
}

sub _call ( $self, $method, $args = undef, $cb = undef ) {
    my $h = $self->{_ws} // $self->_connect;

    my $id = $_MSG_ID++;

    my $cv = P->cv;

    $self->{_cb}->{$id} = sub ( $res ) { $cv->( $cb ? $cb->($res) : $res ) };

    $self->{_ws}->send_text(
        \to_json {
            id     => $id,
            method => $method,
            params => $args,
        }
    );

    return defined wantarray ? $cv->recv : ();
}

sub _connect ( $self ) {
    weaken $self;

    my $h = Pcore::WebSocket::raw->connect(
        "ws://$self->{chrome}->{host}:$self->{chrome}->{port}/devtools/page/$self->{id}",
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
                        $res = res [ 400, "$error->{message} $error->{data}" ], $msg->{result};
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

    $self->{_ws} = $h;

    return $h;
}

# NETWORK
sub network_enable ( $self, $cb = undef ) {
    return $cb ? $cb->( res 200 ) : res 200 if $self->{network_enabled};

    return $self->_call(
        'Network.enable',
        undef,
        sub ($res) {
            $self->{network_enabled} = 1 if $res;

            return $cb ? $cb->($res) : $res;
        }
    );
}

sub network_disable ( $self, $cb = undef ) {
    return $cb ? $cb->( res 200 ) : res 200 if !$self->{network_enabled};

    return $self->_call(
        'Network.disable',
        undef,
        sub ($res) {
            $self->{network_enabled} = 0 if $res;

            return $cb ? $cb->($res) : $res;
        }
    );
}

# PAGE
sub page_enable ( $self, $cb = undef ) {
    return $cb ? $cb->( res 200 ) : res 200 if $self->{page_enabled};

    return $self->_call(
        'Page.enable',
        undef,
        sub ($res) {
            $self->{page_enabled} = 1 if $res;

            return $cb ? $cb->($res) : $res;
        }
    );
}

sub page_disable ( $self, $cb = undef ) {
    return $cb ? $cb->( res 200 ) : res 200 if !$self->{page_enabled};

    return $self->_call(
        'Page.disable',
        undef,
        sub ($res) {
            $self->{page_enabled} = 0 if $res;

            return $cb ? $cb->($res) : $res;
        }
    );
}

# COOKIES
sub get_cookies ( $self, $cb = undef ) {
    weaken $self;

    return $self->_call(
        'Network.getCookies',
        undef,
        sub ( $res ) {
            my $cookies;

            if ( !$res ) {
                warn $res;
            }
            else {
                $cookies = defined $self ? $self->convert_cookies( $res->{data}->{cookies} ) : undef;
            }

            return $cb ? $cb->($cookies) : $cookies;
        }
    );
}

sub convert_cookies ( $self, $chrome_cookies ) {
    my $cookies;

    for my $cookie ( $chrome_cookies->@* ) {
        $cookies->{ $cookie->{domain} }->{ $cookie->{path} }->{ $cookie->{name} } = $cookie;

        $cookie->{val} = delete $cookie->{value};
    }

    return $cookies;
}

# format, png, jpeg
# quality, 0 .. 100, for jpeg only
# clip, { x, y, width, height, scale }
sub get_screenshot ( $self, @args ) {
    my $cb = is_plain_coderef $args[-1] ? pop @args : undef;

    return $self->_call(
        'Page.captureScreenshot',
        {@args},
        sub ( $res ) {
            my $img;

            if ($res) {
                $img = from_b64 $res->{data}->{data};
            }
            else {
                warn $res;
            }

            return $cb ? $cb->($img) : $img;
        }
    );
}

sub navigate_to ( $self, $url, %args ) {
    my $listener     = $self->{listen}->{'Page.loadEventFired'};
    my $page_enabled = $self->{page_enabled};

    my $res;

    if ( !$page_enabled ) {
        $res = $self->page_enable;

        return $res if !$res;
    }

    my $cv = P->cv;

    $self->{listen}->{'Page.loadEventFired'} = sub { $cv->() };

    $res = $self->_call( 'Page.navigate', { url => $url, %args }, undef );

    if ( !$res ) {
        $self->page_disable if !$page_enabled;
        $self->listen( 'Page.loadEventFired', $listener );

        return $res;
    }

    $cv->recv;

    $self->page_disable if !$page_enabled;
    $self->listen( 'Page.loadEventFired', $listener );

    return $res;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Chrome::Tab

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
