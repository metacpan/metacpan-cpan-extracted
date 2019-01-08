package Pcore::XMPP v0.10.13;

use Pcore -dist, -res;
use AnyEvent::XMPP::Client;

our $INTERVAL = 1;

our $XMPP       = AnyEvent::XMPP::Client->new( debug => 0 );
our $ON_CONNECT = {};
our $ON_MESSAGE = {};
our $MSG_BUF    = {};
our $MSG_TIMER;

$XMPP->reg_cb(
    connected => sub ( $xmpp, $acc ) {
        my $jid = $acc->bare_jid;

        if ( my $cbs = delete $ON_CONNECT->{$jid} ) {
            for my $cb ( $cbs->@* ) { $cb->( res 200 ) }
        }

        __PACKAGE__->_send_queued;

        return;
    },
    error => sub ( $xmpp, $acc, $error ) {

        # reconnect
        $xmpp->update_connections if !$acc->is_connected;

        return;
    },
    message => sub ( $xmpp, $acc, $msg ) {
        my $cb = $ON_MESSAGE->{ $acc->bare_jid };

        return if !$cb;

        ( my $from ) = $msg->from =~ m[\A([^/]+)]sm;

        return if !$from;

        my $data = $msg->any_body;

        return if !defined $data;

        $cb->(
            $from, $data,
            sub ($data) {
                if ( defined $data ) {
                    my $reply = $msg->make_reply;

                    $reply->add_body($data);

                    $reply->send;
                }

                return;
            }
        );

        return;
    }
);

sub add_account ( $self, %args ) {
    $XMPP->add_account( %args->@{qw[username password host port connection_args]} );

    $self->on_message( $args{username}, $args{on_message} ) if $args{on_message};

    my $acc = $XMPP->get_account( $args{username} );

    if ( !$acc->is_connected ) {
        $XMPP->update_connections;

        if ( defined wantarray ) {
            my $cv = P->cv;

            push $ON_CONNECT->{ $args{username} }->@*, sub ($res) {
                $cv->($res);

                return;
            };

            return $cv->recv;
        }
        else {
            return;
        }
    }
    else {
        return;
    }
}

sub on_message ( $self, $jid, $cb ) {
    $ON_MESSAGE->{$jid} = $cb;

    return;
}

sub sendmsg ( $self, $from, $to, $msg ) {
    $from = $XMPP->get_account($from);

    return if !$from;

    $MSG_BUF->{"$from-$to"} //= {
        from => $from,
        to   => $to,
        body => [],
    };

    push $MSG_BUF->{"$from-$to"}->{body}->@*, $msg;

    $MSG_TIMER //= AE::timer $INTERVAL, 0, sub {
        undef $MSG_TIMER;

        $self->_send_queued;

        return;
    };

    return;
}

sub _send_queued ( $self ) {
    for my $id ( keys $MSG_BUF->%* ) {

        # delay, if acc is not connected
        next if !$MSG_BUF->{$id}->{from}->is_connected;

        my $msg = delete $MSG_BUF->{$id};

        AnyEvent::XMPP::IM::Message->new(
            to         => $msg->{to},
            body       => join( "\n\n", $msg->{body}->@* ),
            connection => $msg->{from}->connection,
        )->send;
    }

    return;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::XMPP

=head1 SYNOPSIS

    use Pcore::XMPP;

    Pcore::XMPP->add_account(
        username        => 'no-reply@softvisio.net',
        password        => 'password',
        host            => 'talk.google.com',
        port            => undef,              # 5222 by default
        connection_args => undef,
        on_message      => sub ( $from, $data, $reply ) {
            $reply->(time);

            return;
        },
    );

    Pcore::XMPP->sendmsg( 'no-reply@softvisio.net', 'zdm@softvisio.net', 'message' );

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=head1 AUTHOR

zdm <zdm@softvisio.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by zdm.

=cut
