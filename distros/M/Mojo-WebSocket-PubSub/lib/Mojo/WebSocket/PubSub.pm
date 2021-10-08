package Mojo::WebSocket::PubSub;
$Mojo::WebSocket::PubSub::VERSION = '0.04';
use Mojo::Base 'Mojo::EventEmitter';
use Mojo::WebSocket::PubSub::Syntax;
use Mojo::UserAgent;
use Mojo::IOLoop;

has url => 'http://127.0.0.1:9069/psws';
has tx  => undef;
has ua  => sub { state $ua; $ua = Mojo::UserAgent->new };

sub new {
    my $s = shift->SUPER::new(@_);
    $s->{syn} = new Mojo::WebSocket::PubSub::Syntax;

    # Open WebSocket to pubsub service
    $s->ua->websocket_p( $s->url )->then(
        sub {
            my $tx = shift;
            $s->tx($tx);

            # Wait for WebSocket to be closed
            $s->{syn}->on( all => sub { $s->_rcvd( $_[1], $_[2] ) } );
            $s->{syn}->on( broadcast_notify => sub {
                  $s->emit(notify => $_[1]->{msg} ) ;
            } );
            $s->tx->on(
                finish => sub {
                    my ( $tx, $code, $reason ) = @_;
                    say "WebSocket closed with status $code.";
                }
            );
            $s->tx->on(
                json => sub {
                    my ( $tx, $msg ) = @_;
                    $s->{syn}->parse($msg);
                }
            );
            say "WebSocket connected";
            $s->_send_keepalive;
        }
    )->catch(
        sub {
            my $err = shift;

            # Handle failed WebSocket handshakes and other exceptions
            warn "WebSocket error: $err";
        }
    )->wait;
    return $s;
}

sub DESTROY {
    my $s = shift;
    $s->tx(undef);
}

sub listen {
    my $s   = shift;
    my $ch  = shift;
    my $ret = 1;
    new Mojo::Promise(
        sub {
            my ( $r, $f ) = @_;
            $s->{syn}->on( 'listened' => sub { $r->( $_[1] ) } );
            Mojo::IOLoop->timer( 5 => sub { $f->() } );
            $s->_send( $s->{syn}->listen($ch) );
        }
    )->catch( sub { $ret = 0 } )->wait;
    return $ret;
}

sub publish {
    my $s   = shift;
    my $msg = shift;
    my $ret = 1;
    new Mojo::Promise(
        sub {
            my ( $r, $f ) = @_;
            $s->{syn}->on( 'notified' => sub { $r->( $_[1] ) } );
            Mojo::IOLoop->timer( 5 => sub { $f->() } );
            $s->_send( $s->{syn}->notify($msg) );
        }
    )->catch( sub { $ret = 0 } )->wait;
    return $ret;
}

sub _send {
    shift->tx->send( { json => shift } );
}

sub _send_keepalive {
    # send keepalive every inactivity_timeout/2
    state $tid;
    Mojo::IOLoop->remove($tid) if ($tid);
    my $s = shift;
    my $t2 = Mojo::IOLoop->stream($s->tx->connection)->timeout/2;
    say $t2;
    $tid = Mojo::IOLoop->recurring(
         $t2 => sub {
            $s->_send( $s->{syn}->keepalive );
        }
    );
}

sub _rcvd {
    my $s = shift;
    #p @_;
}

1;

=pod

=head1 NAME

Mojo::WebSocket::PubSub - A Mojolicious publish/subscribe channels based on websocket.

=for html <p>
    <a href="https://github.com/emilianobruni/mojo-websocket-pubsub/actions/workflows/test.yml">
        <img alt="github workflow tests" src="https://github.com/emilianobruni/mojo-websocket-pubsub/actions/workflows/test.yml/badge.svg">
    </a>
    <img alt="Top language: " src="https://img.shields.io/github/languages/top/emilianobruni/mojo-websocket-pubsub">
    <img alt="github last commit" src="https://img.shields.io/github/last-commit/emilianobruni/mojo-websocket-pubsub">
</p>

=head1 VERSION

version 0.04

=head1 SYNOPSIS

=head1 DESCRIPTION

A Mojolicious publish/subscribe channels based on websocket.

=encoding UTF-8

=head1 BUGS/CONTRIBUTING

Please report any bugs through the web interface at L<https://github.com/EmilianoBruni/mojo-websocket-pubsub/issues>
If you want to contribute changes or otherwise involve yourself in development, feel free to fork the Git repository from
L<https://github.com/EmilianoBruni/mojo-websocket-pubsub/>.

=head1 SUPPORT

You can find this documentation with the perldoc command too.

    perldoc Mojo::WebSocket::PubSub

=head1 AUTHOR

Emiliano Bruni <info@ebruni.it>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Emiliano Bruni.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: A Mojolicious publish/subscribe channels based on websocket.

