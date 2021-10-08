package Mojo::WebSocket::PubSub::Syntax;
$Mojo::WebSocket::PubSub::Syntax::VERSION = '0.04';
use Mojo::Base 'Mojo::EventEmitter';
use Time::HiRes qw(gettimeofday);

has 'lookup' => \&_lookup;

sub keepalive {
    return { t => 'k' };
}

sub ping() {
    return { t => 'i', cts => [gettimeofday] };
}

sub pong {
    my $s = shift;
    my $ping = shift || return;
    $ping->{t} = 'o';
    $ping->{sts} = [gettimeofday];
    return $ping;
}

sub listen {
    my $s = shift;
    my $ch = shift;
    return {t => 'l', ch => $ch};
}

sub listened {
    my $s = shift;
    my $join = shift || return;
    $join->{t} = 'd';
    return $join;
}

sub notify {
    my $s = shift;
    my $msg = shift || return;
    return {t => 'n', msg => $msg};
}

sub notified {
    my $s = shift;
    my $msg = shift || return;
    $msg->{t} = 'm';
    return $msg;
}

sub broadcast_notify {
    my $s = shift;
    my $msg = shift || return;
    my $from = shift || return;
    $msg->{t} = 'b';
    $msg->{from} = $from;

    return $msg;
}

sub parse {
    my $s   = shift;
    my $msg = shift || return;

    my $cmd = $msg->{t};
    return unless exists $s->lookup->{$cmd};
    my $ll = $s->lookup->{$cmd};

    $s->emit( all          => $ll->{cb}->( $s, $ll->{event}, $msg ) );
    $s->emit( $ll->{event} => $ll->{cb}->( $s, $msg ) );
}

sub _lookup {
    my $s  = shift;
    my $ll = {
        k => {
            event => 'keepalive',
        },
        i => {
            event => 'ping',
            reply => sub { $s->pong($_[0]); },
        },
        o => {
            event => 'pong',
        },
        l => {
            event => 'listen',
            reply => sub { $s->listened($_[0]); },
        },
        d => {
            event => 'listened',
        },
        n => {
            event => 'notify',
            reply => sub { $s->broadcast_notify($_[0], $_[1]) },
        },
        'm' => {
            event => 'notified',
        },
        b => {
            event => 'broadcast_notify',
        },
    };
    foreach ( keys %$ll ) {
        $ll->{$_}->{cb} = sub {shift; return @_};
    }
    return $ll;
}

1;

=pod

=head1 NAME

Mojo::WebSocket::PubSub::Syntax - Syntax parser/builder for communication in Mojo::WebSocket::PubSub

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

Syntax parser/builder for communication in Mojo::WebSocket::PubSub

=encoding UTF-8

=head1 BUGS/CONTRIBUTING

Please report any bugs through the web interface at L<https://github.com/EmilianoBruni/mojo-websocket-pubsub/issues>
If you want to contribute changes or otherwise involve yourself in development, feel free to fork the Git repository from
L<https://github.com/EmilianoBruni/mojo-websocket-pubsub/>.

=head1 SUPPORT

You can find this documentation with the perldoc command too.

    perldoc Mojo::WebSocket::PubSub::Syntax

=head1 AUTHOR

Emiliano Bruni <info@ebruni.it>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Emiliano Bruni.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: Syntax parser/builder for communication in Mojo::WebSocket::PubSub

