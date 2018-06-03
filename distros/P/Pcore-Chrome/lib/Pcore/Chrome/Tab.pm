package Pcore::Chrome::Tab;

use Pcore -class;
use Pcore::Util::Data qw[to_json from_json];
use Pcore::Util::Scalar qw[weaken is_plain_coderef];
use Pcore::WebSocket::raw;

use overload    #
  q[&{}] => sub ( $self, @ ) {
    return sub { return _cmd( $self, @_ ) };
  },
  fallback => undef;

has chrome => ( required => 1 );
has id     => ( required => 1 );

has listen => ();    # HashRef

has _ws      => ();  # ( is => 'ro', isa => InstanceOf ['Pcore::WebSocket::raw'], init_arg => undef );
has _cb      => ();  # ( is => 'ro', isa => HashRef,                                        init_arg => undef );
has _conn_cb => ();  # ( is => 'ro', isa => ArrayRef,                                       init_arg => undef );

our $_MSG_ID = 0;

sub new_tab ( $self, @args ) {
    $self->{chrome}->new_tab(@args);

    return;
}

sub close ( $self, $cb = undef ) {    ## no critic qw[Subroutines::ProhibitBuiltinHomonyms NamingConventions::ProhibitAmbiguousNames]
    return P->http->get(
        "http://$self->{chrome}->{host}:$self->{chrome}->{port}/json/close/$self->{id}",
        sub ($res) {
            return $cb ? $cb->( $self, $res ) : ( $self, $res );
        }
    );
}

sub activate ( $self, $cb = undef ) {
    return P->http->get(
        "http://$self->{chrome}->{host}:$self->{chrome}->{port}/json/activate/$self->{id}",
        sub ($res) {
            return $cb ? $cb->( $self, $res ) : ( $self, $res );
        }
    );
}

sub _cmd ( $self, $cmd, @args ) {
    my $cb = is_plain_coderef $args[-1] ? pop @args : undef;

    my %args = @args;

    my $id = $_MSG_ID++;

    $self->{_cb}->{$id} = [ $self, $cb ] if $cb;

    my $send = sub {
        $self->{_ws}->send_text( to_json {
            id     => $id,
            method => $cmd,
            params => \%args,
        } );

        return;
    };

    if ( $self->{_ws} ) {
        $send->();
    }
    else {
        $self->_connect( sub {
            $send->();

            return;
        } );
    }

    return;
}

sub _connect ( $self, $cb ) {
    push $self->{_conn_cb}->@*, $cb;

    return if $self->{_conn_cb}->@* > 1;

    weaken $self;

    my $c;

    $c = Pcore::WebSocket::raw->new(
        max_message_size => 0,
        compression      => 0,
        on_connect       => sub ( $ws, $headers ) {
            undef $c;

            $self->{_ws} = $ws;

            # call callbacks
            if ( my $callbacks = delete $self->{_conn_cb} ) {
                for my $cb ( $callbacks->@* ) {
                    $cb->();
                }
            }

            return;
        },
        on_disconnect => sub ( $ws, $status ) {
            undef $c;
            undef $self->{_ws};

            # on_connect_error call callbacks
            if ( my $callbacks = delete $self->{_conn_cb} ) {
                for my $cb ( $callbacks->@* ) {
                    $cb->();
                }
            }

            # call pending callbacks
            if ( my $callbacks = delete $self->{_cb} ) {
                for my $cb ( values $callbacks->%* ) {
                    $cb->[1]->( $cb->[0], undef );
                }
            }

            return;
        },
        on_text => sub ( $ws, $data_ref ) {
            my $msg = from_json $data_ref;

            if ( exists $msg->{id} ) {
                if ( my $cb = delete $self->{_cb}->{ $msg->{id} } ) {
                    $cb->[1]->( $cb->[0], $msg->{result} );
                }
            }
            elsif ( $msg->{method} ) {
                if ( my $cb = $self->{listen}->{ $msg->{method} } ) {
                    $cb->( $self, $msg->{method}, $msg->{params} );
                }
            }
            else {
                dump $msg;
            }

            return;
        },
    );

    $c->connect(
        "ws://$self->{chrome}->{host}:$self->{chrome}->{port}/devtools/page/$self->{id}",
        connect_timeout => 1000,
        tls_ctx         => undef,
    );

    return;
}

sub get_cookies ( $self, $cb ) {
    $self->(
        'Network.getCookies',
        sub ( $tab, $data ) {
            $cb->( $tab, $tab->convert_cookies( $data->{cookies} ) );

            return;
        }
    );

    return;
}

sub convert_cookies ( $self, $chrome_cookies ) {
    my $cookies;

    for my $cookie ( $chrome_cookies->@* ) {
        $cookies->{ $cookie->{domain} }->{ $cookie->{path} }->{ $cookie->{name} } = $cookie;

        $cookie->{val} = delete $cookie->{value};
    }

    return $cookies;
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
