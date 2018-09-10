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

has listen => ();    # {method => callback} hook

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

sub _cmd ( $self, $cmd, @args ) {
    my $h = $self->{_ws} // $self->_connect;

    my $cb = is_plain_coderef $args[-1] ? pop @args : undef;

    my $id = $_MSG_ID++;

    my $cv = P->cv;

    $self->{_cb}->{$id} = sub ( $res ) { $cv->( $cb ? $cb->($res) : $res ) };

    $self->{_ws}->send_text( to_json {
        id     => $id,
        method => $cmd,
        params => {@args},
    } );

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
                    $cb->[1]->( $cb->[0], undef );
                }
            }

            return;
        },
        on_text => sub ( $ws, $data_ref ) {
            my $msg = from_json $data_ref;

            if ( exists $msg->{id} ) {
                if ( my $cb = delete $self->{_cb}->{ $msg->{id} } ) {
                    $cb->( $msg->{result} );
                }
            }
            elsif ( $msg->{method} ) {
                if ( my $cb = $self->{listen}->{ $msg->{method} } ) {
                    $cb->( $msg->{method}, $msg->{params} );
                }
            }
            else {
                dump $msg;
            }

            return;
        },
    );

    $self->{_ws} = $h;

    return $h;
}

sub get_cookies ( $self, $cb = undef ) {
    weaken $self;

    return $self->(
        'Network.getCookies',
        sub ( $data ) {
            my $cookies = defined $self ? $self->convert_cookies( $data->{cookies} ) : undef;

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
